#include <ruby.h>
#include <ruby/thread.h>
#include <ruby/thread_native.h>
#include <ruby/debug.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <signal.h>
#include <errno.h>

#include "helpers.h"
#include "ruby_helpers.h"
#include "collectors_thread_context.h"
#include "collectors_dynamic_sampling_rate.h"
#include "collectors_idle_sampling_helper.h"
#include "private_vm_api_access.h"
#include "setup_signal_handler.h"
#include "time_helpers.h"

// Used to trigger the execution of Collectors::ThreadState, which implements all of the sampling logic
// itself; this class only implements the "when to do it" part.
//
// This file implements the native bits of the Datadog::Profiling::Collectors::CpuAndWallTimeWorker class

// ---
// Here be dragons: This component is quite fiddly and probably one of the more complex in the profiler as it deals with
// multiple threads, signal handlers, global state, etc.
//
// ## Design notes for this class:
//
// ### Constraints
//
// Currently, sampling Ruby threads requires calling Ruby VM APIs that are only safe to call while holding on to the
// global VM lock (and are not async-signal safe -- cannot be called from a signal handler).
//
// @ivoanjo: As a note, I don't think we should think of this constraint as set in stone. Since can reach into the Ruby
// internals, we may be able to figure out a way of overcoming it. But it's definitely going to be hard so for now
// we're considering it as a given.
//
// ### Flow for triggering CPU/Wall-time samples
//
// The flow for triggering samples is as follows:
//
// 1. Inside the `run_sampling_trigger_loop` function (running in the `CpuAndWallTimeWorker` background thread),
// a `SIGPROF` signal gets sent to the current process.
//
// 2. The `handle_sampling_signal` signal handler function gets called to handle the `SIGPROF` signal.
//
//   Which thread the signal handler function gets called on by the operating system is quite important. We need to perform
// an operation -- calling the `rb_postponed_job_register_one` API -- that can only be called from the thread that
// is holding on to the global VM lock. So this is the thread we're "hoping" our signal lands on.
//
//   The signal never lands on the `CpuAndWallTimeWorker` background thread because we explicitly block it off from that
// thread in `block_sigprof_signal_handler_from_running_in_current_thread`.
//
//   If the signal lands on a thread that is not holding onto the global VM lock, we can't proceed to the next step,
// and we need to restart the sampling flow from step 1. (There's still quite a few improvements we can make here,
// but this is the current state of the implementation).
//
// 3. Inside `handle_sampling_signal`, if it's getting executed by the Ruby thread that is holding the global VM lock,
// we can call `rb_postponed_job_register_one` to ask the Ruby VM to call our `sample_from_postponed_job` function
// "as soon as it can".
//
// 4. The Ruby VM calls our `sample_from_postponed_job` from a thread holding the global VM lock. A sample is recorded by
// calling `thread_context_collector_sample`.
//
// ### TracePoints and Forking
//
// When the Ruby VM forks, the CPU/Wall-time profiling stops naturally because it's triggered by a background thread
// that doesn't get automatically restarted by the VM on the child process. (The profiler does trigger its restart at
// some point -- see `Profiling::Tasks::Setup` for details).
//
// But this doesn't apply to any `TracePoint`s this class may use, which will continue to be active. Thus, we need to
// always remember consider this case of -- the worker thread may not be alive but the `TracePoint`s can continue to
// trigger samples.
//
// ---

// Contains state for a single CpuAndWallTimeWorker instance
struct cpu_and_wall_time_worker_state {
  // These are immutable after initialization

  bool gc_profiling_enabled;
  bool allocation_counting_enabled;
  bool no_signals_workaround_enabled;
  bool dynamic_sampling_rate_enabled;
  int allocation_sample_every; // Temporarily used for development/testing of allocation profiling
  VALUE self_instance;
  VALUE thread_context_collector_instance;
  VALUE idle_sampling_helper_instance;
  VALUE owner_thread;
  dynamic_sampling_rate_state dynamic_sampling_rate;
  VALUE gc_tracepoint; // Used to get gc start/finish information
  VALUE object_allocation_tracepoint; // Used to get allocation counts and allocation profiling

  // These are mutable and used to signal things between the worker thread and other threads

  atomic_bool should_run;
  // When something goes wrong during sampling, we record the Ruby exception here, so that it can be "re-raised" on
  // the CpuAndWallTimeWorker thread
  VALUE failure_exception;
  // Used by `_native_stop` to flag the worker thread to start (see comment on `_native_sampling_loop`)
  VALUE stop_thread;

  // Others

  // Used to detect/avoid nested sampling, e.g. when the object_allocation_tracepoint gets triggered by a memory allocation
  // that happens during another sample.
  bool during_sample;

  struct stats {
    // How many times we tried to trigger a sample
    unsigned int trigger_sample_attempts;
    // How many times we tried to simulate signal delivery
    unsigned int trigger_simulated_signal_delivery_attempts;
    // How many times we actually simulated signal delivery
    unsigned int simulated_signal_delivery;
    // How many times we actually called rb_postponed_job_register_one from a signal handler
    unsigned int signal_handler_enqueued_sample;
    // How many times the signal handler was called from the wrong thread
    unsigned int signal_handler_wrong_thread;
    // How many times we actually sampled (except GC samples)
    unsigned int sampled;
    // How many times we skipped a sample because of the dynamic sampling rate mechanism
    unsigned int skipped_sample_because_of_dynamic_sampling_rate;

    // Stats for the results of calling rb_postponed_job_register_one
      // The same function was already waiting to be executed
    unsigned int postponed_job_skipped_already_existed;
      // The function was added to the queue successfully
    unsigned int postponed_job_success;
      // The queue was full
    unsigned int postponed_job_full;
      // The function returned an unknown result code
    unsigned int postponed_job_unknown_result;

    // Min/max/total wall-time spent sampling (except GC samples)
    uint64_t sampling_time_ns_min;
    uint64_t sampling_time_ns_max;
    uint64_t sampling_time_ns_total;
    // How many times we saw allocations being done inside a sample
    unsigned int allocations_during_sample;
  } stats;
};

static VALUE _native_new(VALUE klass);
static VALUE _native_initialize(
  DDTRACE_UNUSED VALUE _self,
  VALUE self_instance,
  VALUE thread_context_collector_instance,
  VALUE gc_profiling_enabled,
  VALUE idle_sampling_helper_instance,
  VALUE allocation_counting_enabled,
  VALUE no_signals_workaround_enabled,
  VALUE dynamic_sampling_rate_enabled,
  VALUE allocation_sample_every
);
static void cpu_and_wall_time_worker_typed_data_mark(void *state_ptr);
static VALUE _native_sampling_loop(VALUE self, VALUE instance);
static VALUE _native_stop(DDTRACE_UNUSED VALUE _self, VALUE self_instance, VALUE worker_thread);
static VALUE stop(VALUE self_instance, VALUE optional_exception);
static void handle_sampling_signal(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext);
static void *run_sampling_trigger_loop(void *state_ptr);
static void interrupt_sampling_trigger_loop(void *state_ptr);
static void sample_from_postponed_job(DDTRACE_UNUSED void *_unused);
static VALUE rescued_sample_from_postponed_job(VALUE self_instance);
static VALUE handle_sampling_failure(VALUE self_instance, VALUE exception);
static VALUE _native_current_sigprof_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE release_gvl_and_run_sampling_trigger_loop(VALUE instance);
static VALUE _native_is_running(DDTRACE_UNUSED VALUE self, VALUE instance);
static void testing_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext);
static VALUE _native_install_testing_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE _native_remove_testing_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE _native_trigger_sample(DDTRACE_UNUSED VALUE self);
static VALUE _native_gc_tracepoint(DDTRACE_UNUSED VALUE self, VALUE instance);
static void on_gc_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused);
static void after_gc_from_postponed_job(DDTRACE_UNUSED void *_unused);
static VALUE safely_call(VALUE (*function_to_call_safely)(VALUE), VALUE function_to_call_safely_arg, VALUE instance);
static VALUE _native_simulate_handle_sampling_signal(DDTRACE_UNUSED VALUE self);
static VALUE _native_simulate_sample_from_postponed_job(DDTRACE_UNUSED VALUE self);
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE instance);
static VALUE _native_is_sigprof_blocked_in_current_thread(DDTRACE_UNUSED VALUE self);
static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE instance);
void *simulate_sampling_signal_delivery(DDTRACE_UNUSED void *_unused);
static void grab_gvl_and_sample(void);
static void reset_stats(struct cpu_and_wall_time_worker_state *state);
static void sleep_for(uint64_t time_ns);
static VALUE _native_allocation_count(DDTRACE_UNUSED VALUE self);
static void on_newobj_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused);
static void disable_tracepoints(struct cpu_and_wall_time_worker_state *state);
static VALUE _native_with_blocked_sigprof(DDTRACE_UNUSED VALUE self);
static VALUE rescued_sample_allocation(VALUE tracepoint_data);

// Note on sampler global state safety:
//
// Both `active_sampler_instance` and `active_sampler_instance_state` are **GLOBAL** state. Be careful when accessing
// or modifying them.
// In particular, it's important to only mutate them while holding the global VM lock, to ensure correctness.
//
// This global state is needed because a bunch of functions on this file need to access it from situations
// (e.g. signal handler) where it's impossible or just awkward to pass it as an argument.
static VALUE active_sampler_instance = Qnil;
static struct cpu_and_wall_time_worker_state *active_sampler_instance_state = NULL;

// Used to implement CpuAndWallTimeWorker._native_allocation_count . To be able to use cheap thread-local variables
// (here with `__thread`, see https://gcc.gnu.org/onlinedocs/gcc/Thread-Local.html), this needs to be global.
//
// Carryover of state between profiler instances can happen and is not considered to be a problem -- see expectations for this
// API documented in profiling.rb .
__thread uint64_t allocation_count = 0;

void collectors_cpu_and_wall_time_worker_init(VALUE profiling_module) {
  rb_global_variable(&active_sampler_instance);

  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE collectors_cpu_and_wall_time_worker_class = rb_define_class_under(collectors_module, "CpuAndWallTimeWorker", rb_cObject);
  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(collectors_cpu_and_wall_time_worker_class, "Testing");

  // Instances of the CpuAndWallTimeWorker class are "TypedData" objects.
  // "TypedData" objects are special objects in the Ruby VM that can wrap C structs.
  // In this case, it wraps the cpu_and_wall_time_worker_state.
  //
  // Because Ruby doesn't know how to initialize native-level structs, we MUST override the allocation function for objects
  // of this class so that we can manage this part. Not overriding or disabling the allocation function is a common
  // gotcha for "TypedData" objects that can very easily lead to VM crashes, see for instance
  // https://bugs.ruby-lang.org/issues/18007 for a discussion around this.
  rb_define_alloc_func(collectors_cpu_and_wall_time_worker_class, _native_new);

  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_initialize", _native_initialize, 8);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_sampling_loop", _native_sampling_loop, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_stop", _native_stop, 2);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_reset_after_fork", _native_reset_after_fork, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_stats", _native_stats, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_allocation_count", _native_allocation_count, 0);
  rb_define_singleton_method(testing_module, "_native_current_sigprof_signal_handler", _native_current_sigprof_signal_handler, 0);
  rb_define_singleton_method(testing_module, "_native_is_running?", _native_is_running, 1);
  rb_define_singleton_method(testing_module, "_native_install_testing_signal_handler", _native_install_testing_signal_handler, 0);
  rb_define_singleton_method(testing_module, "_native_remove_testing_signal_handler", _native_remove_testing_signal_handler, 0);
  rb_define_singleton_method(testing_module, "_native_trigger_sample", _native_trigger_sample, 0);
  rb_define_singleton_method(testing_module, "_native_gc_tracepoint", _native_gc_tracepoint, 1);
  rb_define_singleton_method(testing_module, "_native_simulate_handle_sampling_signal", _native_simulate_handle_sampling_signal, 0);
  rb_define_singleton_method(testing_module, "_native_simulate_sample_from_postponed_job", _native_simulate_sample_from_postponed_job, 0);
  rb_define_singleton_method(testing_module, "_native_is_sigprof_blocked_in_current_thread", _native_is_sigprof_blocked_in_current_thread, 0);
  rb_define_singleton_method(testing_module, "_native_with_blocked_sigprof", _native_with_blocked_sigprof, 0);
}

// This structure is used to define a Ruby object that stores a pointer to a struct cpu_and_wall_time_worker_state
// See also https://github.com/ruby/ruby/blob/master/doc/extension.rdoc for how this works
static const rb_data_type_t cpu_and_wall_time_worker_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::Collectors::CpuAndWallTimeWorker",
  .function = {
    .dmark = cpu_and_wall_time_worker_typed_data_mark,
    .dfree = RUBY_DEFAULT_FREE,
    .dsize = NULL, // We don't track memory usage (although it'd be cool if we did!)
    //.dcompact = NULL, // FIXME: Add support for compaction
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE _native_new(VALUE klass) {
  struct cpu_and_wall_time_worker_state *state = ruby_xcalloc(1, sizeof(struct cpu_and_wall_time_worker_state));

  // Note: Any exceptions raised from this note until the TypedData_Wrap_Struct call will lead to the state memory
  // being leaked.

  state->gc_profiling_enabled = false;
  state->allocation_counting_enabled = false;
  state->no_signals_workaround_enabled = false;
  state->dynamic_sampling_rate_enabled = true;
  state->allocation_sample_every = 0;
  state->thread_context_collector_instance = Qnil;
  state->idle_sampling_helper_instance = Qnil;
  state->owner_thread = Qnil;
  dynamic_sampling_rate_init(&state->dynamic_sampling_rate);
  state->gc_tracepoint = Qnil;
  state->object_allocation_tracepoint = Qnil;

  atomic_init(&state->should_run, false);
  state->failure_exception = Qnil;
  state->stop_thread = Qnil;

  state->during_sample = false;

  reset_stats(state);

  return state->self_instance = TypedData_Wrap_Struct(klass, &cpu_and_wall_time_worker_typed_data, state);
}

static VALUE _native_initialize(
  DDTRACE_UNUSED VALUE _self,
  VALUE self_instance,
  VALUE thread_context_collector_instance,
  VALUE gc_profiling_enabled,
  VALUE idle_sampling_helper_instance,
  VALUE allocation_counting_enabled,
  VALUE no_signals_workaround_enabled,
  VALUE dynamic_sampling_rate_enabled,
  VALUE allocation_sample_every
) {
  ENFORCE_BOOLEAN(gc_profiling_enabled);
  ENFORCE_BOOLEAN(allocation_counting_enabled);
  ENFORCE_BOOLEAN(no_signals_workaround_enabled);
  ENFORCE_BOOLEAN(dynamic_sampling_rate_enabled);
  ENFORCE_TYPE(allocation_sample_every, T_FIXNUM);

  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  state->gc_profiling_enabled = (gc_profiling_enabled == Qtrue);
  state->allocation_counting_enabled = (allocation_counting_enabled == Qtrue);
  state->no_signals_workaround_enabled = (no_signals_workaround_enabled == Qtrue);
  state->dynamic_sampling_rate_enabled = (dynamic_sampling_rate_enabled == Qtrue);
  state->allocation_sample_every = NUM2INT(allocation_sample_every);

  if (state->allocation_sample_every < 0) {
    rb_raise(rb_eArgError, "Unexpected value for allocation_sample_every: %d. This value must be >= 0.", state->allocation_sample_every);
  }

  state->thread_context_collector_instance = enforce_thread_context_collector_instance(thread_context_collector_instance);
  state->idle_sampling_helper_instance = idle_sampling_helper_instance;
  state->gc_tracepoint = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_GC_ENTER | RUBY_INTERNAL_EVENT_GC_EXIT, on_gc_event, NULL /* unused */);
  state->object_allocation_tracepoint = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_NEWOBJ, on_newobj_event, NULL /* unused */);

  return Qtrue;
}

// Since our state contains references to Ruby objects, we need to tell the Ruby GC about them
static void cpu_and_wall_time_worker_typed_data_mark(void *state_ptr) {
  struct cpu_and_wall_time_worker_state *state = (struct cpu_and_wall_time_worker_state *) state_ptr;

  rb_gc_mark(state->thread_context_collector_instance);
  rb_gc_mark(state->idle_sampling_helper_instance);
  rb_gc_mark(state->owner_thread);
  rb_gc_mark(state->failure_exception);
  rb_gc_mark(state->stop_thread);
  rb_gc_mark(state->gc_tracepoint);
  rb_gc_mark(state->object_allocation_tracepoint);
}

// Called in a background thread created in CpuAndWallTimeWorker#start
static VALUE _native_sampling_loop(DDTRACE_UNUSED VALUE _self, VALUE instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  struct cpu_and_wall_time_worker_state *old_state = active_sampler_instance_state;
  if (old_state != NULL) {
    if (is_thread_alive(old_state->owner_thread)) {
      rb_raise(
        rb_eRuntimeError,
        "Could not start CpuAndWallTimeWorker: There's already another instance of CpuAndWallTimeWorker active in a different thread"
      );
    } else {
      // The previously active thread seems to have died without cleaning up after itself.
      // In this case, we can still go ahead and start the profiler BUT we make sure to disable any existing tracepoint
      // first as:
      // a) If this is a new instance of the CpuAndWallTimeWorker, we don't want the tracepoint from the old instance
      //    being kept around
      // b) If this is the same instance of the CpuAndWallTimeWorker if we call enable on a tracepoint that is already
      //    enabled, it will start firing more than once, see https://bugs.ruby-lang.org/issues/19114 for details.
      disable_tracepoints(old_state);
    }
  }

  // We use `stop_thread` to distinguish when `_native_stop` was called before we actually had a chance to start. In this
  // situation we stop immediately and never even start the sampling trigger loop.
  if (state->stop_thread == rb_thread_current()) return Qnil;

  // Reset the dynamic sampling rate state, if any (reminder: the monotonic clock reference may change after a fork)
  dynamic_sampling_rate_reset(&state->dynamic_sampling_rate);

  // This write to a global is thread-safe BECAUSE we're still holding on to the global VM lock at this point
  active_sampler_instance_state = state;
  active_sampler_instance = instance;
  state->owner_thread = rb_thread_current();

  atomic_store(&state->should_run, true);

  block_sigprof_signal_handler_from_running_in_current_thread(); // We want to interrupt the thread with the global VM lock, never this one

  // Release GVL, get to the actual work!
  int exception_state;
  rb_protect(release_gvl_and_run_sampling_trigger_loop, instance, &exception_state);

  // The sample trigger loop finished (either cleanly or with an error); let's clean up

  disable_tracepoints(state);

  active_sampler_instance_state = NULL;
  active_sampler_instance = Qnil;
  state->owner_thread = Qnil;

  // If this `Thread` is about to die, why is this important? It's because Ruby caches native threads for a period after
  // the `Thread` dies, and reuses them if a new Ruby `Thread` gets created. This means that while conceptually the
  // worker background `Thread` is about to die, the low-level native OS thread can be reused for something else in the Ruby app.
  // Then, the reused thread would "inherit" the SIGPROF blocking, which is... really unexpected.
  // This actually caused a flaky test -- the `native_extension_spec.rb` creates a `Thread` and tries to specifically
  // send SIGPROF signals to it, and oops it could fail if it got the reused native thread from the worker which still
  // had SIGPROF delivery blocked. :hide_the_pain_harold:
  unblock_sigprof_signal_handler_from_running_in_current_thread();

  // Why replace and not use remove the signal handler? We do this because when a process receives a SIGPROF without
  // having an explicit signal handler set up, the process will instantly terminate with a confusing
  // "Profiling timer expired" message left behind. (This message doesn't come from us -- it's the default message for
  // an unhandled SIGPROF. Pretty confusing UNIX/POSIX behavior...)
  //
  // Unfortunately, because signal delivery is asynchronous, there's no way to guarantee that there are no pending
  // profiler-sent signals by the time we get here and want to clean up.
  // @ivoanjo: I suspect this will never happen, but the cost of getting it wrong is really high (VM terminates) so this
  // is a just-in-case situation.
  //
  // Note 2: This can raise exceptions as well, so make sure that all cleanups are done by the time we get here.
  replace_sigprof_signal_handler_with_empty_handler(handle_sampling_signal);

  // Ensure that instance is not garbage collected while the native sampling loop is running; this is probably not needed, but just in case
  RB_GC_GUARD(instance);

  if (exception_state) rb_jump_tag(exception_state); // Re-raise any exception that happened

  return Qnil;
}

static VALUE _native_stop(DDTRACE_UNUSED VALUE _self, VALUE self_instance, VALUE worker_thread) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  state->stop_thread = worker_thread;

  return stop(self_instance, /* optional_exception: */ Qnil);
}

static VALUE stop(VALUE self_instance, VALUE optional_exception) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  atomic_store(&state->should_run, false);
  state->failure_exception = optional_exception;

  // Disable the tracepoints as soon as possible, so the VM doesn't keep on calling them
  disable_tracepoints(state);

  return Qtrue;
}

// NOTE: Remember that this will run in the thread and within the scope of user code, including user C code.
// We need to be careful not to change any state that may be observed OR to restore it if we do. For instance, if anything
// we do here can set `errno`, then we must be careful to restore the old `errno` after the fact.
static void handle_sampling_signal(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the signal delivery was happening; nothing to do
  if (state == NULL) return;

  if (
    !ruby_native_thread_p() || // Not a Ruby thread
    !is_current_thread_holding_the_gvl() || // Not safe to enqueue a sample from this thread
    !ddtrace_rb_ractor_main_p() // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  ) {
    state->stats.signal_handler_wrong_thread++;
    return;
  }

  // We implicitly assume there can be no concurrent nor nested calls to handle_sampling_signal because
  // a) we get triggered using SIGPROF, and the docs state a second SIGPROF will not interrupt an existing one
  // b) we validate we are in the thread that has the global VM lock; if a different thread gets a signal, it will return early
  //    because it will not have the global VM lock

  // Note: rb_postponed_job_register_one ensures that if there's a previous sample_from_postponed_job queued for execution
  // then we will not queue a second one. It does this by doing a linear scan on the existing jobs; in the future we
  // may want to implement that check ourselves.

  state->stats.signal_handler_enqueued_sample++;

  // Note: If we ever want to get rid of rb_postponed_job_register_one, remember not to clobber Ruby exceptions, as
  // this function does this helpful job for us now -- https://github.com/ruby/ruby/commit/a98e343d39c4d7bf1e2190b076720f32d9f298b3.
  int result = rb_postponed_job_register_one(0, sample_from_postponed_job, NULL);

  // Officially, the result of rb_postponed_job_register_one is documented as being opaque, but in practice it does not
  // seem to have changed between Ruby 2.3 and 3.2, and so we track it as a debugging mechanism
  switch (result) {
    case 0:
      state->stats.postponed_job_full++; break;
    case 1:
      state->stats.postponed_job_success++; break;
    case 2:
      state->stats.postponed_job_skipped_already_existed++; break;
    default:
      state->stats.postponed_job_unknown_result++;
  }
}

// The actual sampling trigger loop always runs **without** the global vm lock.
static void *run_sampling_trigger_loop(void *state_ptr) {
  struct cpu_and_wall_time_worker_state *state = (struct cpu_and_wall_time_worker_state *) state_ptr;

  uint64_t minimum_time_between_signals = MILLIS_AS_NS(10);

  while (atomic_load(&state->should_run)) {
    state->stats.trigger_sample_attempts++;

    if (state->no_signals_workaround_enabled) {
      // In the no_signals_workaround_enabled mode, the profiler never sends SIGPROF signals.
      //
      // This is a fallback for a few incompatibilities and limitations -- see the code that decides when to enable
      // `no_signals_workaround_enabled` in `Profiling::Component` for details.
      //
      // Thus, we instead pretty please ask Ruby to let us run. This means profiling data can be biased by when the Ruby
      // scheduler chooses to schedule us.
      state->stats.trigger_simulated_signal_delivery_attempts++;
      grab_gvl_and_sample(); // Note: Can raise exceptions
    } else {
      current_gvl_owner owner = gvl_owner();
      if (owner.valid) {
        // Note that reading the GVL owner and sending them a signal is a race -- the Ruby VM keeps on executing while
        // we're doing this, so we may still not signal the correct thread from time to time, but our signal handler
        // includes a check to see if it got called in the right thread
        pthread_kill(owner.owner, SIGPROF);
      } else {
        // If no thread owns the Global VM Lock, the application is probably idle at the moment. We still want to sample
        // so we "ask a friend" (the IdleSamplingHelper component) to grab the GVL and simulate getting a SIGPROF.
        //
        // In a previous version of the code, we called `grab_gvl_and_sample` directly BUT this was problematic because
        // Ruby may concurrently get busy and so the CpuAndWallTimeWorker would be blocked in line to acquire the GVL
        // for an uncontrolled amount of time. (This can still happen to the IdleSamplingHelper, but the
        // CpuAndWallTimeWorker will still be free to interrupt the Ruby VM and keep sampling for the entire blocking period).
        state->stats.trigger_simulated_signal_delivery_attempts++;
        idle_sampling_helper_request_action(state->idle_sampling_helper_instance, grab_gvl_and_sample);
      }
    }

    sleep_for(minimum_time_between_signals);

    // The dynamic sampling rate module keeps track of how long samples are taking, and in here we extend our sleep time
    // to take that into account.
    // Note that we deliberately should NOT combine this sleep_for with the one above because the result of
    // `dynamic_sampling_rate_get_sleep` may have changed while the above sleep was ongoing.
    uint64_t extra_sleep =
      dynamic_sampling_rate_get_sleep(&state->dynamic_sampling_rate, monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE));
    if (state->dynamic_sampling_rate_enabled && extra_sleep > 0) sleep_for(extra_sleep);
  }

  return NULL; // Unused
}

// This is called by the Ruby VM when it wants to shut down the background thread
static void interrupt_sampling_trigger_loop(void *state_ptr) {
  struct cpu_and_wall_time_worker_state *state = (struct cpu_and_wall_time_worker_state *) state_ptr;

  atomic_store(&state->should_run, false);
}

static void sample_from_postponed_job(DDTRACE_UNUSED void *_unused) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the postponed job was waiting to be executed; nothing to do
  if (state == NULL) return;

  // @ivoanjo: I'm not sure this can ever happen because `handle_sampling_signal` only enqueues this callback if
  // it's running on the main Ractor, but just in case...
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  state->during_sample = true;

  // Rescue against any exceptions that happen during sampling
  safely_call(rescued_sample_from_postponed_job, state->self_instance, state->self_instance);

  state->during_sample = false;
}

static VALUE rescued_sample_from_postponed_job(VALUE self_instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  long wall_time_ns_before_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);

  if (state->dynamic_sampling_rate_enabled && !dynamic_sampling_rate_should_sample(&state->dynamic_sampling_rate, wall_time_ns_before_sample)) {
    state->stats.skipped_sample_because_of_dynamic_sampling_rate++;
    return Qnil;
  }

  state->stats.sampled++;

  VALUE profiler_overhead_stack_thread = state->owner_thread; // Used to attribute profiler overhead to a different stack
  thread_context_collector_sample(state->thread_context_collector_instance, wall_time_ns_before_sample, profiler_overhead_stack_thread);

  long wall_time_ns_after_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);
  long delta_ns = wall_time_ns_after_sample - wall_time_ns_before_sample;

  // Guard against wall-time going backwards, see https://github.com/DataDog/dd-trace-rb/pull/2336 for discussion.
  uint64_t sampling_time_ns = delta_ns < 0 ? 0 : delta_ns;

  state->stats.sampling_time_ns_min = uint64_min_of(sampling_time_ns, state->stats.sampling_time_ns_min);
  state->stats.sampling_time_ns_max = uint64_max_of(sampling_time_ns, state->stats.sampling_time_ns_max);
  state->stats.sampling_time_ns_total += sampling_time_ns;

  dynamic_sampling_rate_after_sample(&state->dynamic_sampling_rate, wall_time_ns_after_sample, sampling_time_ns);

  // Return a dummy VALUE because we're called from rb_rescue2 which requires it
  return Qnil;
}

static VALUE handle_sampling_failure(VALUE self_instance, VALUE exception) {
  stop(self_instance, exception);
  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_current_sigprof_signal_handler(DDTRACE_UNUSED VALUE self) {
  struct sigaction existing_signal_handler_config = {.sa_sigaction = NULL};
  if (sigaction(SIGPROF, NULL, &existing_signal_handler_config) != 0) {
    rb_sys_fail("Failed to probe existing handler");
  }

  if (existing_signal_handler_config.sa_sigaction == handle_sampling_signal) {
    return ID2SYM(rb_intern("profiling"));
  } else if (existing_signal_handler_config.sa_sigaction == empty_signal_handler) {
    return ID2SYM(rb_intern("empty"));
  } else if (existing_signal_handler_config.sa_sigaction != NULL) {
    return ID2SYM(rb_intern("other"));
  } else {
    return Qnil;
  }
}

static VALUE release_gvl_and_run_sampling_trigger_loop(VALUE instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  // Final preparations: Setup signal handler and enable tracepoints. We run these here and not in `_native_sampling_loop`
  // because they may raise exceptions.
  install_sigprof_signal_handler(handle_sampling_signal, "handle_sampling_signal");
  if (state->gc_profiling_enabled) rb_tracepoint_enable(state->gc_tracepoint);
  if (state->allocation_counting_enabled) rb_tracepoint_enable(state->object_allocation_tracepoint);

  rb_thread_call_without_gvl(run_sampling_trigger_loop, state, interrupt_sampling_trigger_loop, state);

  // If we stopped sampling due to an exception, re-raise it (now in the worker thread)
  if (state->failure_exception != Qnil) rb_exc_raise(state->failure_exception);

  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_is_running(DDTRACE_UNUSED VALUE self, VALUE instance) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  return (state != NULL && is_thread_alive(state->owner_thread) && state->self_instance == instance) ? Qtrue : Qfalse;
}

static void testing_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext) {
  /* Does nothing on purpose */
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_install_testing_signal_handler(DDTRACE_UNUSED VALUE self) {
  install_sigprof_signal_handler(testing_signal_handler, "testing_signal_handler");
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_remove_testing_signal_handler(DDTRACE_UNUSED VALUE self) {
  remove_sigprof_signal_handler();
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_trigger_sample(DDTRACE_UNUSED VALUE self) {
  sample_from_postponed_job(NULL);
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_gc_tracepoint(DDTRACE_UNUSED VALUE self, VALUE instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  return state->gc_tracepoint;
}

// Implements tracking of cpu-time and wall-time spent doing GC. This function is called by Ruby from the `gc_tracepoint`
// when the RUBY_INTERNAL_EVENT_GC_ENTER and RUBY_INTERNAL_EVENT_GC_EXIT events are triggered.
//
// See the comments on
// * thread_context_collector_on_gc_start
// * thread_context_collector_on_gc_finish
// * thread_context_collector_sample_after_gc
//
// For the expected times in which to call them, and their assumptions.
//
// Safety: This function gets called while Ruby is doing garbage collection. While Ruby is doing garbage collection,
// *NO ALLOCATION* is allowed. This function, and any it calls must never trigger memory or object allocation.
// This includes exceptions and use of ruby_xcalloc (because xcalloc can trigger GC)!
static void on_gc_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused) {
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  int event = rb_tracearg_event_flag(rb_tracearg_from_tracepoint(tracepoint_data));
  if (event != RUBY_INTERNAL_EVENT_GC_ENTER && event != RUBY_INTERNAL_EVENT_GC_EXIT) return; // Unknown event

  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because the tracepoint is always enabled after the instance is set
  // and disabled before it is cleared, but just in case...
  if (state == NULL) return;

  if (event == RUBY_INTERNAL_EVENT_GC_ENTER) {
    thread_context_collector_on_gc_start(state->thread_context_collector_instance);
  } else if (event == RUBY_INTERNAL_EVENT_GC_EXIT) {
    // Design: In an earlier iteration of this feature (see https://github.com/DataDog/dd-trace-rb/pull/2308) we
    // actually had a single method to implement the behavior of both thread_context_collector_on_gc_finish
    // and thread_context_collector_sample_after_gc (the latter is called via after_gc_from_postponed_job).
    //
    // Unfortunately, then we discovered the safety issue around no allocations, and thus decided to separate them -- so that
    // the sampling could run outside the tight safety constraints of the garbage collection process.
    //
    // There is a downside: The sample is now taken very very shortly afterwards the GC finishes, and not immediately
    // as the GC finishes, which means the stack captured may by affected by "skid", e.g. point slightly after where
    // it should be pointing at.
    // Alternatives to solve this would be to capture no stack for garbage collection (as we do for Java and .net);
    // making the sampling process allocation-safe (very hard); or separate stack sampling from sample recording,
    // e.g. enabling us to capture the stack in thread_context_collector_on_gc_finish and do the rest later
    // (medium hard).

    thread_context_collector_on_gc_finish(state->thread_context_collector_instance);
    // We use rb_postponed_job_register_one to ask Ruby to run thread_context_collector_sample_after_gc after if
    // fully finishes the garbage collection, so that one is allowed to do allocations and throw exceptions as usual.
    //
    // Note: If we ever want to get rid of rb_postponed_job_register_one, remember not to clobber Ruby exceptions, as
    // this function does this helpful job for us now -- https://github.com/ruby/ruby/commit/a98e343d39c4d7bf1e2190b076720f32d9f298b3.
    rb_postponed_job_register_one(0, after_gc_from_postponed_job, NULL);
  }
}

static void after_gc_from_postponed_job(DDTRACE_UNUSED void *_unused) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the postponed job was waiting to be executed; nothing to do
  if (state == NULL) return;

  // @ivoanjo: I'm not sure this can ever happen because `on_gc_event` only enqueues this callback if
  // it's running on the main Ractor, but just in case...
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  state->during_sample = true;

  // Trigger sampling using the Collectors::ThreadState; rescue against any exceptions that happen during sampling
  safely_call(thread_context_collector_sample_after_gc, state->thread_context_collector_instance, state->self_instance);

  state->during_sample = false;
}

// Equivalent to Ruby begin/rescue call, where we call a C function and jump to the exception handler if an
// exception gets raised within
static VALUE safely_call(VALUE (*function_to_call_safely)(VALUE), VALUE function_to_call_safely_arg, VALUE instance) {
  VALUE exception_handler_function_arg = instance;
  return rb_rescue2(
    function_to_call_safely,
    function_to_call_safely_arg,
    handle_sampling_failure,
    exception_handler_function_arg,
    rb_eException, // rb_eException is the base class of all Ruby exceptions
    0 // Required by API to be the last argument
  );
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_simulate_handle_sampling_signal(DDTRACE_UNUSED VALUE self) {
  handle_sampling_signal(0, NULL, NULL);
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_simulate_sample_from_postponed_job(DDTRACE_UNUSED VALUE self) {
  sample_from_postponed_job(NULL);
  return Qtrue;
}

// After the Ruby VM forks, this method gets called in the child process to clean up any leftover state from the parent.
//
// Assumption: This method gets called BEFORE restarting profiling. Note that profiling-related tracepoints may still
// be active, so we make sure to disable them before calling into anything else, so that there are no components
// attempting to trigger samples at the same time as the reset is done.
//
// In the future, if we add more other components with tracepoints, we will need to coordinate stopping all such
// tracepoints before doing the other cleaning steps.
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  // Disable all tracepoints, so that there are no more attempts to mutate the profile
  disable_tracepoints(state);

  reset_stats(state);

  // Remove all state from the `Collectors::ThreadState` and connected downstream components
  rb_funcall(state->thread_context_collector_instance, rb_intern("reset_after_fork"), 0);

  return Qtrue;
}

static VALUE _native_is_sigprof_blocked_in_current_thread(DDTRACE_UNUSED VALUE self) {
  return is_sigprof_blocked_in_current_thread();
}

static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE instance) {
  struct cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, struct cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  VALUE pretty_sampling_time_ns_min = state->stats.sampling_time_ns_min == UINT64_MAX ? Qnil : ULL2NUM(state->stats.sampling_time_ns_min);
  VALUE pretty_sampling_time_ns_max = state->stats.sampling_time_ns_max == 0 ? Qnil : ULL2NUM(state->stats.sampling_time_ns_max);
  VALUE pretty_sampling_time_ns_total = state->stats.sampling_time_ns_total == 0 ? Qnil : ULL2NUM(state->stats.sampling_time_ns_total);
  VALUE pretty_sampling_time_ns_avg =
    state->stats.sampled == 0 ? Qnil : DBL2NUM(((double) state->stats.sampling_time_ns_total) / state->stats.sampled);

  VALUE stats_as_hash = rb_hash_new();
  VALUE arguments[] = {
    ID2SYM(rb_intern("trigger_sample_attempts")),                    /* => */ UINT2NUM(state->stats.trigger_sample_attempts),
    ID2SYM(rb_intern("trigger_simulated_signal_delivery_attempts")), /* => */ UINT2NUM(state->stats.trigger_simulated_signal_delivery_attempts),
    ID2SYM(rb_intern("simulated_signal_delivery")),                  /* => */ UINT2NUM(state->stats.simulated_signal_delivery),
    ID2SYM(rb_intern("signal_handler_enqueued_sample")),             /* => */ UINT2NUM(state->stats.signal_handler_enqueued_sample),
    ID2SYM(rb_intern("signal_handler_wrong_thread")),                /* => */ UINT2NUM(state->stats.signal_handler_wrong_thread),
    ID2SYM(rb_intern("sampled")),                                    /* => */ UINT2NUM(state->stats.sampled),
    ID2SYM(rb_intern("skipped_sample_because_of_dynamic_sampling_rate")), /* => */ UINT2NUM(state->stats.skipped_sample_because_of_dynamic_sampling_rate),
    ID2SYM(rb_intern("postponed_job_skipped_already_existed")),      /* => */ UINT2NUM(state->stats.postponed_job_skipped_already_existed),
    ID2SYM(rb_intern("postponed_job_success")),                      /* => */ UINT2NUM(state->stats.postponed_job_success),
    ID2SYM(rb_intern("postponed_job_full")),                         /* => */ UINT2NUM(state->stats.postponed_job_full),
    ID2SYM(rb_intern("postponed_job_unknown_result")),               /* => */ UINT2NUM(state->stats.postponed_job_unknown_result),
    ID2SYM(rb_intern("sampling_time_ns_min")),                       /* => */ pretty_sampling_time_ns_min,
    ID2SYM(rb_intern("sampling_time_ns_max")),                       /* => */ pretty_sampling_time_ns_max,
    ID2SYM(rb_intern("sampling_time_ns_total")),                     /* => */ pretty_sampling_time_ns_total,
    ID2SYM(rb_intern("sampling_time_ns_avg")),                       /* => */ pretty_sampling_time_ns_avg,
    ID2SYM(rb_intern("allocations_during_sample")),                  /* => */ UINT2NUM(state->stats.allocations_during_sample),
  };
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(stats_as_hash, arguments[i], arguments[i+1]);
  return stats_as_hash;
}

void *simulate_sampling_signal_delivery(DDTRACE_UNUSED void *_unused) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the IdleSamplingHelper was trying to execute this action
  if (state == NULL) return NULL;

  state->stats.simulated_signal_delivery++;

  // @ivoanjo: We could instead directly call sample_from_postponed_job, but I chose to go through the signal handler
  // so that the simulated case is as close to the original one as well (including any metrics increases, etc).
  handle_sampling_signal(0, NULL, NULL);

  return NULL; // Unused
}

static void grab_gvl_and_sample(void) { rb_thread_call_with_gvl(simulate_sampling_signal_delivery, NULL); }

static void reset_stats(struct cpu_and_wall_time_worker_state *state) {
  state->stats = (struct stats) {}; // Resets all stats back to zero
  state->stats.sampling_time_ns_min = UINT64_MAX; // Since we always take the min between existing and latest sample
}

static void sleep_for(uint64_t time_ns) {
  // As a simplification, we currently only support setting .tv_nsec
  if (time_ns >= SECONDS_AS_NS(1)) {
    grab_gvl_and_raise(rb_eArgError, "sleep_for can only sleep for less than 1 second, time_ns: %"PRIu64, time_ns);
  }

  struct timespec time_to_sleep = {.tv_nsec = time_ns};

  while (nanosleep(&time_to_sleep, &time_to_sleep) != 0) {
    if (errno == EINTR) {
      // We were interrupted. nanosleep updates "time_to_sleep" to contain only the remaining time, so we just let the
      // loop keep going.
    } else {
      ENFORCE_SUCCESS_NO_GVL(errno);
    }
  }
}

static VALUE _native_allocation_count(DDTRACE_UNUSED VALUE self) {
  bool is_profiler_running = active_sampler_instance_state != NULL;

  return is_profiler_running ? ULL2NUM(allocation_count) : Qnil;
}

// Implements memory-related profiling events. This function is called by Ruby via the `object_allocation_tracepoint`
// when the RUBY_INTERNAL_EVENT_NEWOBJ event is triggered.
static void on_newobj_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused) {
  // Update thread-local allocation count
  if (RB_UNLIKELY(allocation_count == UINT64_MAX)) {
    allocation_count = 0;
  } else {
    allocation_count++;
  }

  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because the tracepoint is always enabled after the instance is set
  // and disabled before it is cleared, but just in case...
  if (state == NULL) return;

  // In a few cases, we may actually be allocating an object as part of profiler sampling. We don't want to recursively
  // sample, so we just return early
  if (state->during_sample) {
    state->stats.allocations_during_sample++;
    return;
  }

  // @ivoanjo: Strictly speaking, this is not needed because Ruby should not call the same tracepoint while a previous
  // invocation is still pending, (e.g. it wouldn't call `on_newobj_event` while it's already running), but I decided
  // to keep this here for consistency -- every call to the thread context (other than the special gc calls which are
  // defined as not being able to allocate) sets this.
  state->during_sample = true;

  // TODO: This is a placeholder sampling decision strategy. We plan to replace it with a better one soon (e.g. before
  // beta), and having something here allows us to test the rest of feature, sampling decision aside.
  if (state->allocation_sample_every > 0 && ((allocation_count % state->allocation_sample_every) == 0)) {
    // Rescue against any exceptions that happen during sampling
    safely_call(rescued_sample_allocation, tracepoint_data, state->self_instance);
  }

  state->during_sample = false;
}

static void disable_tracepoints(struct cpu_and_wall_time_worker_state *state) {
  rb_tracepoint_disable(state->gc_tracepoint);
  rb_tracepoint_disable(state->object_allocation_tracepoint);
}

static VALUE _native_with_blocked_sigprof(DDTRACE_UNUSED VALUE self) {
  block_sigprof_signal_handler_from_running_in_current_thread();
  int exception_state;
  VALUE result = rb_protect(rb_yield, Qundef, &exception_state);
  unblock_sigprof_signal_handler_from_running_in_current_thread();

  if (exception_state) {
    rb_jump_tag(exception_state);
  } else {
    return result;
  }
}

static VALUE rescued_sample_allocation(VALUE tracepoint_data) {
  struct cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because on_newobj_event already checked for this, but just in case...
  if (state == NULL) return Qnil;

  rb_trace_arg_t *data = rb_tracearg_from_tracepoint(tracepoint_data);
  VALUE new_object = rb_tracearg_object(data);

  thread_context_collector_sample_allocation(state->thread_context_collector_instance, state->allocation_sample_every, new_object);

  // Return a dummy VALUE because we're called from rb_rescue2 which requires it
  return Qnil;
}
