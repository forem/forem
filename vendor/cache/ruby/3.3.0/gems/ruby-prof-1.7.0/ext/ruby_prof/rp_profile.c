/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

   /* Document-class: RubyProf::Profile

   The Profile class represents a single profiling run and provides the main API for using ruby-prof.
   After creating a Profile instance, start profiling code by calling the Profile#start method. To finish profiling,
   call Profile#stop. Once profiling is completed, the Profile instance contains the results.

     profile = RubyProf::Profile.new
     profile.start
     ...
     result = profile.stop

   Alternatively, you can use the block syntax:

     profile = RubyProf::Profile.profile do
       ...
     end
   */

#include <assert.h>

#include "rp_allocation.h"
#include "rp_call_trees.h"
#include "rp_call_tree.h"
#include "rp_profile.h"
#include "rp_method.h"

VALUE cProfile;

/* support tracing ruby events from ruby-prof. useful for getting at
 what actually happens inside the ruby interpreter (and ruby-prof).
 set environment variable RUBY_PROF_TRACE to filename you want to
 find the trace in.
 */
FILE* trace_file = NULL;

static const char* get_event_name(rb_event_flag_t event)
{
    switch (event) {
    case RUBY_EVENT_LINE:
        return "line";
    case RUBY_EVENT_CLASS:
        return "class";
    case RUBY_EVENT_END:
        return "end";
    case RUBY_EVENT_CALL:
        return "call";
    case RUBY_EVENT_RETURN:
        return "return";
    case RUBY_EVENT_B_CALL:
        return "b-call";
    case RUBY_EVENT_B_RETURN:
        return "b-return";
    case RUBY_EVENT_C_CALL:
        return "c-call";
    case RUBY_EVENT_C_RETURN:
        return "c-return";
    case RUBY_EVENT_THREAD_BEGIN:
        return "thread-begin";
    case RUBY_EVENT_THREAD_END:
        return "thread-end";
    case RUBY_EVENT_FIBER_SWITCH:
        return "fiber-switch";
    case RUBY_EVENT_RAISE:
        return "raise";
    case RUBY_INTERNAL_EVENT_NEWOBJ:
        return "newobj";
    default:
        return "unknown";
    }
}

thread_data_t* check_fiber(prof_profile_t* profile, double measurement)
{
    thread_data_t* result = NULL;

    // Get the current fiber
    VALUE fiber = rb_fiber_current();

    /* We need to switch the profiling context if we either had none before,
     we don't merge fibers and the fiber ids differ, or the thread ids differ. */
    if (profile->last_thread_data->fiber != fiber)
    {
        result = threads_table_lookup(profile, fiber);
        if (!result)
        {
            result = threads_table_insert(profile, fiber);
        }
        switch_thread(profile, result, measurement);
    }
    else
    {
        result = profile->last_thread_data;
    }
    return result;
}

static int excludes_method(st_data_t key, prof_profile_t* profile)
{
    return (profile->exclude_methods_tbl &&
            method_table_lookup(profile->exclude_methods_tbl, key) != NULL);
}

static prof_method_t* create_method(prof_profile_t* profile, st_data_t key, VALUE klass, VALUE msym, VALUE source_file, int source_line)
{
    prof_method_t* result = prof_method_create(profile, klass, msym, source_file, source_line);
    method_table_insert(profile->last_thread_data->method_table, result->key, result);

    return result;
}

static prof_method_t* check_parent_method(prof_profile_t* profile, thread_data_t* thread_data)
{
    VALUE msym = ID2SYM(rb_intern("_inserted_parent_"));
    st_data_t key = method_key(cProfile, msym);

    prof_method_t* result = method_table_lookup(thread_data->method_table, key);

    if (!result)
    {
        result = create_method(profile, key, cProfile, msym, Qnil, 0);
    }

    return result;
}

prof_method_t* check_method(prof_profile_t* profile, rb_trace_arg_t* trace_arg, rb_event_flag_t event, thread_data_t* thread_data)
{
    VALUE klass = rb_tracearg_defined_class(trace_arg);

    /* Special case - skip any methods from the mProf
     module or cProfile class since they clutter
     the results but aren't important to them results. */
    if (klass == cProfile)
        return NULL;

    VALUE msym = rb_tracearg_callee_id(trace_arg);

    st_data_t key = method_key(klass, msym);

    if (excludes_method(key, profile))
        return NULL;

    prof_method_t* result = method_table_lookup(thread_data->method_table, key);

    if (!result)
    {
        VALUE source_file = (event != RUBY_EVENT_C_CALL ? rb_tracearg_path(trace_arg) : Qnil);
        int source_line = (event != RUBY_EVENT_C_CALL ? FIX2INT(rb_tracearg_lineno(trace_arg)) : 0);
        result = create_method(profile, key, klass, msym, source_file, source_line);
    }

    return result;
}

/* ===========  Profiling ================= */
static void prof_trace(prof_profile_t* profile, rb_trace_arg_t* trace_arg, double measurement)
{
    static VALUE last_fiber = Qnil;
    VALUE fiber = rb_fiber_current();

    rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
    const char* event_name = get_event_name(event);

    VALUE source_file = rb_tracearg_path(trace_arg);
    int source_line = FIX2INT(rb_tracearg_lineno(trace_arg));

    VALUE msym = rb_tracearg_callee_id(trace_arg);

    unsigned int klass_flags;
    VALUE klass = rb_tracearg_defined_class(trace_arg);
    VALUE resolved_klass = resolve_klass(klass, &klass_flags);
    const char* class_name = "";

    if (resolved_klass != Qnil)
        class_name = rb_class2name(resolved_klass);

    if (last_fiber != fiber)
    {
        fprintf(trace_file, "\n");
    }

    const char* method_name_char = (msym != Qnil ? rb_id2name(SYM2ID(msym)) : "");
    const char* source_file_char = (source_file != Qnil ? StringValuePtr(source_file) : "");

    fprintf(trace_file, "%2lu:%2f %-8s %s#%s    %s:%2d\n",
            FIX2ULONG(fiber), (double)measurement,
            event_name, class_name, method_name_char, source_file_char, source_line);
    fflush(trace_file);
    last_fiber = fiber;
}

static void prof_event_hook(VALUE trace_point, void* data)
{
    prof_profile_t* profile = (prof_profile_t*)(data);

    rb_trace_arg_t* trace_arg = rb_tracearg_from_tracepoint(trace_point);
    double measurement = prof_measure(profile->measurer, trace_arg);
    rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
    VALUE self = rb_tracearg_self(trace_arg);

    if (trace_file != NULL)
    {
        prof_trace(profile, trace_arg, measurement);
    }

    /* Special case - skip any methods from the mProf
     module since they clutter the results but aren't important. */
    if (self == mProf)
        return;

    thread_data_t* thread_data = check_fiber(profile, measurement);

    if (!thread_data->trace)
        return;

    switch (event)
    {
        case RUBY_EVENT_LINE:
        {
            prof_frame_t* frame = prof_frame_current(thread_data->stack);

            /* If there is no frame then this is either the first method being profiled or we have climbed the
               call stack higher than where we started. */
            if (!frame)
            {
                prof_method_t* method = check_method(profile, trace_arg, event, thread_data);

                if (!method)
                    break;

                prof_call_tree_t* call_tree = prof_call_tree_create(method, NULL, method->source_file, method->source_line);
                prof_add_call_tree(method->call_trees, call_tree);

                // We have climbed higher in the stack then where we started
                if (thread_data->call_tree)
                {
                    prof_call_tree_add_parent(thread_data->call_tree, call_tree);
                    frame = prof_frame_unshift(thread_data->stack, call_tree, thread_data->call_tree, measurement);
                }
                // This is the first method to be profiled
                else
                {
                    frame = prof_frame_push(thread_data->stack, call_tree, measurement, RTEST(profile->paused));
                }

                thread_data->call_tree = call_tree;
            }

            frame->source_file = rb_tracearg_path(trace_arg);
            frame->source_line = FIX2INT(rb_tracearg_lineno(trace_arg));

            break;
        }
        case RUBY_EVENT_CALL:
        case RUBY_EVENT_C_CALL:
        {
            prof_method_t* method = check_method(profile, trace_arg, event, thread_data);

            if (!method)
                break;

            prof_frame_t* frame = prof_frame_current(thread_data->stack);
            prof_call_tree_t* parent_call_tree = NULL;
            prof_call_tree_t* call_tree = NULL;

            // Frame can be NULL if we are switching from one fiber to another (see FiberTest#fiber_test)
            if (frame)
            {
                parent_call_tree = frame->call_tree;
                call_tree = call_tree_table_lookup(parent_call_tree->children, method->key);
            }
            else if (!frame && thread_data->call_tree)
            {
                // There is no current parent - likely we have returned out of the highest level method we have profiled so far.
                // This can happen with enumerators (see fiber_test.rb). So create a new dummy parent.
                prof_method_t* parent_method = check_parent_method(profile, thread_data);
                parent_call_tree = prof_call_tree_create(parent_method, NULL, Qnil, 0);
                prof_add_call_tree(parent_method->call_trees, parent_call_tree);
                prof_call_tree_add_parent(thread_data->call_tree, parent_call_tree);
                frame = prof_frame_unshift(thread_data->stack, parent_call_tree, thread_data->call_tree, measurement);
                thread_data->call_tree = parent_call_tree;
            }

            if (!call_tree)
            {
                // This call info does not yet exist.  So create it and add it to previous CallTree's children and the current method.
                call_tree = prof_call_tree_create(method, parent_call_tree, frame ? frame->source_file : Qnil, frame? frame->source_line : 0);
                prof_add_call_tree(method->call_trees, call_tree);
                if (parent_call_tree)
                    prof_call_tree_add_child(parent_call_tree, call_tree);
            }

            if (!thread_data->call_tree)
                thread_data->call_tree = call_tree;

            // Push a new frame onto the stack for a new c-call or ruby call (into a method)
            prof_frame_t* next_frame = prof_frame_push(thread_data->stack, call_tree, measurement, RTEST(profile->paused));
            next_frame->source_file = method->source_file;
            next_frame->source_line = method->source_line;
            break;
        }
        case RUBY_EVENT_RETURN:
        case RUBY_EVENT_C_RETURN:
        {
            // We need to check for excluded methods so that we don't pop them off the stack
            prof_method_t* method = check_method(profile, trace_arg, event, thread_data);

            if (!method)
                break;

            prof_frame_pop(thread_data->stack, measurement);
            break;
        }
        case RUBY_INTERNAL_EVENT_NEWOBJ:
        {
            /* We want to assign the allocations lexically, not the execution context (otherwise all allocations will
             show up under Class#new */
            int source_line = FIX2INT(rb_tracearg_lineno(trace_arg));
            VALUE source_file = rb_tracearg_path(trace_arg);

            prof_method_t* method = prof_find_method(thread_data->stack, source_file, source_line);
            if (method)
                prof_allocate_increment(method->allocations_table, trace_arg);

            break;
        }
    }
}

void prof_install_hook(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    VALUE event_tracepoint = rb_tracepoint_new(Qnil,
                                               RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
                                               RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN |
                                               RUBY_EVENT_LINE,
                                               prof_event_hook, profile);
    rb_ary_push(profile->tracepoints, event_tracepoint);

    if (profile->measurer->track_allocations)
    {
        VALUE allocation_tracepoint = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_NEWOBJ, prof_event_hook, profile);
        rb_ary_push(profile->tracepoints, allocation_tracepoint);
    }

    for (int i = 0; i < RARRAY_LEN(profile->tracepoints); i++)
    {
        rb_tracepoint_enable(rb_ary_entry(profile->tracepoints, i));
    }
}

void prof_remove_hook(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    for (int i = 0; i < RARRAY_LEN(profile->tracepoints); i++)
    {
        rb_tracepoint_disable(rb_ary_entry(profile->tracepoints, i));
    }
    rb_ary_clear(profile->tracepoints);
}

prof_profile_t* prof_get_profile(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    return RTYPEDDATA_DATA(self);
}

static int collect_threads(st_data_t key, st_data_t value, st_data_t result)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    if (thread_data->trace && thread_data->call_tree)
    {
        VALUE threads_array = (VALUE)result;
        rb_ary_push(threads_array, prof_thread_wrap(thread_data));
    }
    return ST_CONTINUE;
}

/* ========  Profile Class ====== */
static int mark_threads(st_data_t key, st_data_t value, st_data_t result)
{
    thread_data_t* thread = (thread_data_t*)value;
    prof_thread_mark(thread);
    return ST_CONTINUE;
}

static int prof_profile_mark_methods(st_data_t key, st_data_t value, st_data_t result)
{
    prof_method_t* method = (prof_method_t*)value;
    prof_method_mark(method);
    return ST_CONTINUE;
}

static void prof_profile_mark(void* data)
{
    prof_profile_t* profile = (prof_profile_t*)data;
    rb_gc_mark_movable(profile->object);
    rb_gc_mark_movable(profile->tracepoints);
    rb_gc_mark_movable(profile->running);
    rb_gc_mark_movable(profile->paused);

    // If GC stress is true (useful for debugging), when threads_table_create is called in the
    // allocate method Ruby will immediately call this mark method. Thus the threads_tbl will be NULL.
    if (profile->threads_tbl)
        rb_st_foreach(profile->threads_tbl, mark_threads, 0);

    if (profile->exclude_methods_tbl)
        rb_st_foreach(profile->exclude_methods_tbl, prof_profile_mark_methods, 0);
}

void prof_profile_compact(void* data)
{
    prof_profile_t* profile = (prof_profile_t*)data;
    profile->object = rb_gc_location(profile->object);
    profile->tracepoints = rb_gc_location(profile->tracepoints);
    profile->running = rb_gc_location(profile->running);
    profile->paused = rb_gc_location(profile->paused);
}

/* Freeing the profile creates a cascade of freeing. It frees its threads table, which frees
   each thread and its associated call treee and methods. */
static void prof_profile_ruby_gc_free(void* data)
{
    prof_profile_t* profile = (prof_profile_t*)data;
    profile->last_thread_data = NULL;

    threads_table_free(profile->threads_tbl);
    profile->threads_tbl = NULL;

    if (profile->exclude_threads_tbl)
    {
        rb_st_free_table(profile->exclude_threads_tbl);
        profile->exclude_threads_tbl = NULL;
    }

    if (profile->include_threads_tbl)
    {
        rb_st_free_table(profile->include_threads_tbl);
        profile->include_threads_tbl = NULL;
    }

    /* This table owns the excluded sentinels for now. */
    method_table_free(profile->exclude_methods_tbl);
    profile->exclude_methods_tbl = NULL;

    xfree(profile->measurer);
    profile->measurer = NULL;

    xfree(profile);
}

size_t prof_profile_size(const void* data)
{
    return sizeof(prof_profile_t);
}

static const rb_data_type_t profile_type =
{
    .wrap_struct_name = "Profile",
    .function =
    {
        .dmark = prof_profile_mark,
        .dfree = prof_profile_ruby_gc_free,
        .dsize = prof_profile_size,
        .dcompact = prof_profile_compact
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE prof_allocate(VALUE klass)
{
    VALUE result;
    prof_profile_t* profile;
    result = TypedData_Make_Struct(klass, prof_profile_t, &profile_type, profile);
    profile->object = result;
    profile->threads_tbl = threads_table_create();
    profile->exclude_threads_tbl = NULL;
    profile->include_threads_tbl = NULL;
    profile->running = Qfalse;
    profile->allow_exceptions = false;
    profile->exclude_methods_tbl = method_table_create();
    profile->running = Qfalse;
    profile->tracepoints = rb_ary_new();
    return result;
}

static void prof_exclude_common_methods(VALUE profile)
{
    rb_funcall(profile, rb_intern("exclude_common_methods!"), 0);
}

static int pop_frames(VALUE key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;
    double measurement = prof_measure(profile->measurer, NULL);

    if (profile->last_thread_data->fiber != thread_data->fiber)
        switch_thread(profile, thread_data, measurement);

    while (prof_frame_pop(thread_data->stack, measurement));

    return ST_CONTINUE;
}

static void
prof_stop_threads(prof_profile_t* profile)
{
    rb_st_foreach(profile->threads_tbl, pop_frames, (st_data_t)profile);
}

/* call-seq:
   new()
   new(keyword_args)

   Returns a new profiler. Possible keyword arguments include:

   measure_mode:      Measure mode. Specifies the profile measure mode.
                      If not specified, defaults to RubyProf::WALL_TIME.
   allow_exceptions:  Whether to raise exceptions encountered during profiling,
                      or to suppress all exceptions during profiling
   track_allocations: Whether to track object allocations while profiling. True or false.
   exclude_common:    Exclude common methods from the profile. True or false.
   exclude_threads:   Threads to exclude from the profiling results.
   include_threads:   Focus profiling on only the given threads. This will ignore
                      all other threads. */
static VALUE prof_initialize(int argc, VALUE* argv, VALUE self)
{
    VALUE keywords;
    rb_scan_args_kw(RB_SCAN_ARGS_KEYWORDS, argc, argv, ":", &keywords);

    ID table[] = {rb_intern("measure_mode"),
                  rb_intern("track_allocations"),
                  rb_intern("allow_exceptions"),
                  rb_intern("exclude_common"),
                  rb_intern("exclude_threads"),
                  rb_intern("include_threads") };
    VALUE values[6];
    rb_get_kwargs(keywords, table, 0, 6, values);

    VALUE mode = values[0] == Qundef ? INT2NUM(MEASURE_WALL_TIME) : values[0];
    VALUE track_allocations = values[1] == Qtrue ? Qtrue : Qfalse;
    VALUE allow_exceptions = values[2] == Qtrue ? Qtrue : Qfalse;
    VALUE exclude_common = values[3] == Qtrue ? Qtrue : Qfalse;
    VALUE exclude_threads = values[4];
    VALUE include_threads = values[5];

    Check_Type(mode, T_FIXNUM);
    prof_profile_t* profile = prof_get_profile(self);
    profile->measurer = prof_measurer_create(NUM2INT(mode), RB_TEST(track_allocations));
    profile->allow_exceptions = RB_TEST(allow_exceptions);

    if (exclude_threads != Qundef)
    {
        Check_Type(exclude_threads, T_ARRAY);
        assert(profile->exclude_threads_tbl == NULL);
        profile->exclude_threads_tbl = threads_table_create();
        for (int i = 0; i < RARRAY_LEN(exclude_threads); i++)
        {
            VALUE thread = rb_ary_entry(exclude_threads, i);
            rb_st_insert(profile->exclude_threads_tbl, thread, Qtrue);
        }
    }

    if (include_threads != Qundef)
    {
        Check_Type(include_threads, T_ARRAY);
        assert(profile->include_threads_tbl == NULL);
        profile->include_threads_tbl = threads_table_create();
        for (int i = 0; i < RARRAY_LEN(include_threads); i++)
        {
            VALUE thread = rb_ary_entry(include_threads, i);
            rb_st_insert(profile->include_threads_tbl, thread, Qtrue);
        }
    }

    if (RB_TEST(exclude_common))
    {
        prof_exclude_common_methods(self);
    }

    return self;
}

/* call-seq:
   paused? -> boolean

   Returns whether a profile is currently paused.*/
static VALUE prof_paused(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return profile->paused;
}

/* call-seq:
   running? -> boolean

   Returns whether a profile is currently running.*/
static VALUE
prof_running(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return profile->running;
}

/* call-seq:
   mode -> measure_mode

   Returns the measure mode used in this profile.*/
static VALUE prof_profile_measure_mode(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return INT2NUM(profile->measurer->mode);
}

/* call-seq:
   track_allocations -> boolean

   Returns if object allocations were tracked in this profile.*/
static VALUE prof_profile_track_allocations(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return profile->measurer->track_allocations ? Qtrue : Qfalse;
}

/* call-seq:
   start -> self

   Starts recording profile data.*/
static VALUE prof_start(VALUE self)
{
    char* trace_file_name;

    prof_profile_t* profile = prof_get_profile(self);

    if (profile->running == Qtrue)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    profile->running = Qtrue;
    profile->paused = Qfalse;
    profile->last_thread_data = threads_table_insert(profile, rb_fiber_current());

    /* open trace file if environment wants it */
    trace_file_name = getenv("RUBY_PROF_TRACE");

    if (trace_file_name != NULL)
    {
        if (strcmp(trace_file_name, "stdout") == 0)
        {
            trace_file = stdout;
        }
        else if (strcmp(trace_file_name, "stderr") == 0)
        {
            trace_file = stderr;
        }
        else
        {
            trace_file = fopen(trace_file_name, "w");
        }
    }

    prof_install_hook(self);
    return self;
}

/* call-seq:
   pause -> self

   Pauses collecting profile data. */
static VALUE prof_pause(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    if (profile->paused == Qfalse)
    {
        profile->paused = Qtrue;
        profile->measurement_at_pause_resume = prof_measure(profile->measurer, NULL);
        rb_st_foreach(profile->threads_tbl, pause_thread, (st_data_t)profile);
    }

    return self;
}

/* call-seq:
   resume -> self
   resume(&block) -> self

   Resumes recording profile data.*/
static VALUE prof_resume(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    if (profile->paused == Qtrue)
    {
        profile->paused = Qfalse;
        profile->measurement_at_pause_resume = prof_measure(profile->measurer, NULL);
        rb_st_foreach(profile->threads_tbl, unpause_thread, (st_data_t)profile);
    }

    return rb_block_given_p() ? rb_ensure(rb_yield, self, prof_pause, self) : self;
}

/* call-seq:
   stop -> self

   Stops collecting profile data.*/
static VALUE prof_stop(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was not yet called");
    }

    prof_remove_hook(self);

    /* close trace file if open */
    if (trace_file != NULL)
    {
        if (trace_file != stderr && trace_file != stdout)
        {
            fclose(trace_file);
        }
        trace_file = NULL;
    }

    prof_stop_threads(profile);

    /* Unset the last_thread_data (very important!)
       and the threads table */
    profile->running = profile->paused = Qfalse;
    profile->last_thread_data = NULL;

    return self;
}

/* call-seq:
   threads -> Array of RubyProf::Thread

Returns an array of RubyProf::Thread instances that were profiled. */
static VALUE prof_threads(VALUE self)
{
    VALUE result = rb_ary_new();
    prof_profile_t* profile = prof_get_profile(self);
    rb_st_foreach(profile->threads_tbl, collect_threads, result);
    return result;
}

/* call-seq:
   add_thread(thread) -> thread

Adds the specified RubyProf thread to the profile. */
static VALUE prof_add_thread(VALUE self, VALUE thread)
{
  prof_profile_t* profile_ptr = prof_get_profile(self);

  // This thread is now going to be owned by C
  thread_data_t* thread_ptr = prof_get_thread(thread);
  thread_ptr->owner = OWNER_C;

  rb_st_insert(profile_ptr->threads_tbl, thread_ptr->fiber_id, (st_data_t)thread_ptr);
  return thread;
}

/* call-seq:
   remove_thread(thread) -> thread

Removes the specified thread from the profile. This is used to remove threads
after they have been merged togher. Retuns the removed thread. */
static VALUE prof_remove_thread(VALUE self, VALUE thread)
{
  prof_profile_t* profile_ptr = prof_get_profile(self);
  thread_data_t* thread_ptr = prof_get_thread(thread);
  VALUE fiber_id = thread_ptr->fiber_id;
  rb_st_delete(profile_ptr->threads_tbl, (st_data_t*)&fiber_id, NULL);
  return thread;
}

/* Document-method: RubyProf::Profile#Profile
   call-seq:
   profile(&block) -> self

   Profiles the specified block.

     profile = RubyProf::Profile.new
     profile.profile do
       ..
     end
*/
static VALUE prof_profile_instance(VALUE self)
{
    int result;
    prof_profile_t* profile = prof_get_profile(self);

    if (!rb_block_given_p())
    {
        rb_raise(rb_eArgError, "A block must be provided to the profile method.");
    }

    prof_start(self);
    rb_protect(rb_yield, self, &result);
    self = prof_stop(self);

    if (profile->allow_exceptions && result != 0)
    {
        rb_jump_tag(result);
    }

    return self;
}

/* Document-method: RubyProf::Profile::Profile
   call-seq:
   profile(&block) -> RubyProf::Profile
   profile(options, &block) -> RubyProf::Profile

   Profiles the specified block and returns a RubyProf::Profile
   object. Arguments are passed to Profile initialize method.

     profile = RubyProf::Profile.profile do
       ..
     end
*/
static VALUE prof_profile_class(int argc, VALUE* argv, VALUE klass)
{
    return prof_profile_instance(rb_class_new_instance(argc, argv, cProfile));
}

/* call-seq:
   exclude_method!(module, method_name) -> self

   Excludes the method from profiling results.
*/
static VALUE prof_exclude_method(VALUE self, VALUE klass, VALUE msym)
{
    prof_profile_t* profile = prof_get_profile(self);

    if (profile->running == Qtrue)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    st_data_t key = method_key(klass, msym);
    prof_method_t* method = method_table_lookup(profile->exclude_methods_tbl, key);

    if (!method)
    {
        method = prof_method_create(profile, klass, msym, Qnil, 0);
        method_table_insert(profile->exclude_methods_tbl, method->key, method);
    }

    return self;
}

/* :nodoc: */
VALUE prof_profile_dump(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
  
    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("threads")), prof_threads(self));
    rb_hash_aset(result, ID2SYM(rb_intern("measurer_mode")), INT2NUM(profile->measurer->mode));
    rb_hash_aset(result, ID2SYM(rb_intern("measurer_track_allocations")), 
                 profile->measurer->track_allocations ? Qtrue : Qfalse);

    return result;
}

/* :nodoc: */
VALUE prof_profile_load(VALUE self, VALUE data)
{
    prof_profile_t* profile = prof_get_profile(self);

    VALUE measurer_mode = rb_hash_aref(data, ID2SYM(rb_intern("measurer_mode")));
    VALUE measurer_track_allocations = rb_hash_aref(data, ID2SYM(rb_intern("measurer_track_allocations")));
    profile->measurer = prof_measurer_create((prof_measure_mode_t)(NUM2INT(measurer_mode)),
                                              measurer_track_allocations == Qtrue ? true : false);

    VALUE threads = rb_hash_aref(data, ID2SYM(rb_intern("threads")));
    for (int i = 0; i < rb_array_len(threads); i++)
    {
        VALUE thread = rb_ary_entry(threads, i);
        thread_data_t* thread_data = prof_get_thread(thread);
        rb_st_insert(profile->threads_tbl, (st_data_t)thread_data->fiber_id, (st_data_t)thread_data);
    }

    return data;
}

void rp_init_profile(void)
{
    cProfile = rb_define_class_under(mProf, "Profile", rb_cObject);
    rb_define_alloc_func(cProfile, prof_allocate);

    rb_define_singleton_method(cProfile, "profile", prof_profile_class, -1);
    rb_define_method(cProfile, "initialize", prof_initialize, -1);
    rb_define_method(cProfile, "profile", prof_profile_instance, 0);
    rb_define_method(cProfile, "start", prof_start, 0);
    rb_define_method(cProfile, "stop", prof_stop, 0);
    rb_define_method(cProfile, "resume", prof_resume, 0);
    rb_define_method(cProfile, "pause", prof_pause, 0);
    rb_define_method(cProfile, "running?", prof_running, 0);
    rb_define_method(cProfile, "paused?", prof_paused, 0);

    rb_define_method(cProfile, "exclude_method!", prof_exclude_method, 2);
    rb_define_method(cProfile, "measure_mode", prof_profile_measure_mode, 0);
    rb_define_method(cProfile, "track_allocations?", prof_profile_track_allocations, 0);

    rb_define_method(cProfile, "threads", prof_threads, 0);
    rb_define_method(cProfile, "add_thread", prof_add_thread, 1);
    rb_define_method(cProfile, "remove_thread", prof_remove_thread, 1);

    rb_define_method(cProfile, "_dump_data", prof_profile_dump, 0);
    rb_define_method(cProfile, "_load_data", prof_profile_load, 1);
}
