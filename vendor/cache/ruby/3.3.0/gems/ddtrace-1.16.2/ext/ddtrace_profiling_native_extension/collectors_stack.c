#include <ruby.h>
#include <ruby/debug.h>
#include "extconf.h"
#include "helpers.h"
#include "libdatadog_helpers.h"
#include "ruby_helpers.h"
#include "private_vm_api_access.h"
#include "stack_recorder.h"
#include "collectors_stack.h"

// Gathers stack traces from running threads, storing them in a StackRecorder instance
// This file implements the native bits of the Datadog::Profiling::Collectors::Stack class

#define MAX_FRAMES_LIMIT            10000
#define MAX_FRAMES_LIMIT_AS_STRING "10000"

static VALUE missing_string = Qnil;

// Used as scratch space during sampling
struct sampling_buffer {
  unsigned int max_frames;
  VALUE *stack_buffer;
  int *lines_buffer;
  bool *is_ruby_frame;
  ddog_prof_Location *locations;
}; // Note: typedef'd in the header to sampling_buffer

static VALUE _native_sample(
  VALUE self,
  VALUE thread,
  VALUE recorder_instance,
  VALUE metric_values_hash,
  VALUE labels_array,
  VALUE numeric_labels_array,
  VALUE max_frames,
  VALUE in_gc
);
static void maybe_add_placeholder_frames_omitted(VALUE thread, sampling_buffer* buffer, char *frames_omitted_message, int frames_omitted_message_size);
static void record_placeholder_stack_in_native_code(
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sampling_buffer *record_buffer,
  int extra_frames_in_record_buffer
);
static void sample_thread_internal(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sampling_buffer *record_buffer,
  int extra_frames_in_record_buffer
);

void collectors_stack_init(VALUE profiling_module) {
  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE collectors_stack_class = rb_define_class_under(collectors_module, "Stack", rb_cObject);
  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(collectors_stack_class, "Testing");

  rb_define_singleton_method(testing_module, "_native_sample", _native_sample, 7);

  missing_string = rb_str_new2("");
  rb_global_variable(&missing_string);
}

// This method exists only to enable testing Datadog::Profiling::Collectors::Stack behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_sample(
  DDTRACE_UNUSED VALUE _self,
  VALUE thread,
  VALUE recorder_instance,
  VALUE metric_values_hash,
  VALUE labels_array,
  VALUE numeric_labels_array,
  VALUE max_frames,
  VALUE in_gc
) {
  ENFORCE_TYPE(metric_values_hash, T_HASH);
  ENFORCE_TYPE(labels_array, T_ARRAY);
  ENFORCE_TYPE(numeric_labels_array, T_ARRAY);

  VALUE zero = INT2NUM(0);
  sample_values values = {
    .cpu_time_ns   = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("cpu-time"),      zero)),
    .cpu_or_wall_samples = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("cpu-samples"), zero)),
    .wall_time_ns  = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("wall-time"),     zero)),
    .alloc_samples = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("alloc-samples"), zero)),
  };

  long labels_count = RARRAY_LEN(labels_array) + RARRAY_LEN(numeric_labels_array);
  ddog_prof_Label labels[labels_count];
  ddog_prof_Label *state_label = NULL;

  for (int i = 0; i < RARRAY_LEN(labels_array); i++) {
    VALUE key_str_pair = rb_ary_entry(labels_array, i);

    labels[i] = (ddog_prof_Label) {
      .key = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 0)),
      .str = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 1))
    };

    if (rb_str_equal(rb_ary_entry(key_str_pair, 0), rb_str_new_cstr("state"))) {
      state_label = &labels[i];
    }
  }
  for (int i = 0; i < RARRAY_LEN(numeric_labels_array); i++) {
    VALUE key_str_pair = rb_ary_entry(numeric_labels_array, i);

    labels[i + RARRAY_LEN(labels_array)] = (ddog_prof_Label) {
      .key = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 0)),
      .num = NUM2ULL(rb_ary_entry(key_str_pair, 1))
    };
  }

  int max_frames_requested = NUM2INT(max_frames);
  if (max_frames_requested < 0) rb_raise(rb_eArgError, "Invalid max_frames: value must not be negative");

  sampling_buffer *buffer = sampling_buffer_new(max_frames_requested);

  ddog_prof_Slice_Label slice_labels = {.ptr = labels, .len = labels_count};

  sample_thread(
    thread,
    buffer,
    recorder_instance,
    values,
    (sample_labels) {.labels = slice_labels, .state_label = state_label},
    RTEST(in_gc) ? SAMPLE_IN_GC : SAMPLE_REGULAR
  );

  sampling_buffer_free(buffer);

  return Qtrue;
}

void sample_thread(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sample_type type
) {
  // Samples thread into recorder
  if (type == SAMPLE_REGULAR) {
    sampling_buffer *record_buffer = buffer;
    int extra_frames_in_record_buffer = 0;
    sample_thread_internal(thread, buffer, recorder_instance, values, labels, record_buffer, extra_frames_in_record_buffer);
    return;
  }

  // Samples thread into recorder, including as a top frame in the stack a frame named "Garbage Collection"
  if (type == SAMPLE_IN_GC) {
    ddog_CharSlice function_name = DDOG_CHARSLICE_C("");
    ddog_CharSlice function_filename = DDOG_CHARSLICE_C("Garbage Collection");
    buffer->locations[0] = (ddog_prof_Location) {
      .function = (ddog_prof_Function) {.name = function_name, .filename = function_filename},
      .line = 0
    };
    // To avoid changing sample_thread_internal, we just prepare a new buffer struct that uses the same underlying storage as the
    // original buffer, but has capacity one less, so that we can keep the above Garbage Collection frame untouched.
    sampling_buffer thread_in_gc_buffer = (struct sampling_buffer) {
      .max_frames = buffer->max_frames - 1,
      .stack_buffer = buffer->stack_buffer + 1,
      .lines_buffer = buffer->lines_buffer + 1,
      .is_ruby_frame = buffer->is_ruby_frame + 1,
      .locations = buffer->locations + 1,
    };
    sampling_buffer *record_buffer = buffer; // We pass in the original buffer as the record_buffer, but not as the regular buffer
    int extra_frames_in_record_buffer = 1;
    sample_thread_internal(thread, &thread_in_gc_buffer, recorder_instance, values, labels, record_buffer, extra_frames_in_record_buffer);
    return;
  }

  rb_raise(rb_eArgError, "Unexpected value for sample_type: %d", type);
}

#define CHARSLICE_EQUALS(must_be_a_literal, charslice) (strlen("" must_be_a_literal) == charslice.len && strncmp(must_be_a_literal, charslice.ptr, charslice.len) == 0)

// Idea: Should we release the global vm lock (GVL) after we get the data from `rb_profile_frames`? That way other Ruby threads
// could continue making progress while the sample was ingested into the profile.
//
// Other things to take into consideration if we go in that direction:
// * Is it safe to call `rb_profile_frame_...` methods on things from the `stack_buffer` without the GVL acquired?
// * We need to make `VALUE` references in the `stack_buffer` visible to the Ruby GC
// * Should we move this into a different thread entirely?
// * If we don't move it into a different thread, does releasing the GVL on a Ruby thread mean that we're introducing
//   a new thread switch point where there previously was none?
//
// ---
//
// Why the weird extra record_buffer and extra_frames_in_record_buffer?
// The answer is: to support both sample_thread() and sample_thread_in_gc().
//
// For sample_thread(), buffer == record_buffer and extra_frames_in_record_buffer == 0, so it's a no-op.
// For sample_thread_in_gc(), the buffer is a special buffer that is the same as the record_buffer, but with every
// pointer shifted forward extra_frames_in_record_buffer elements, so that the caller can actually inject those extra
// frames, and this function doesn't have to care about it.
static void sample_thread_internal(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sampling_buffer *record_buffer,
  int extra_frames_in_record_buffer
) {
  int captured_frames = ddtrace_rb_profile_frames(
    thread,
    0 /* stack starting depth */,
    buffer->max_frames,
    buffer->stack_buffer,
    buffer->lines_buffer,
    buffer->is_ruby_frame
  );

  if (captured_frames == PLACEHOLDER_STACK_IN_NATIVE_CODE) {
    record_placeholder_stack_in_native_code(
      buffer,
      recorder_instance,
      values,
      labels,
      record_buffer,
      extra_frames_in_record_buffer
    );
    return;
  }

  // Ruby does not give us path and line number for methods implemented using native code.
  // The convention in Kernel#caller_locations is to instead use the path and line number of the first Ruby frame
  // on the stack that is below (e.g. directly or indirectly has called) the native method.
  // Thus, we keep that frame here to able to replicate that behavior.
  // (This is why we also iterate the sampling buffers backwards below -- so that it's easier to keep the last_ruby_frame)
  VALUE last_ruby_frame = Qnil;
  int last_ruby_line = 0;

  ddog_prof_Label *state_label = labels.state_label;
  bool cpu_or_wall_sample = values.cpu_or_wall_samples > 0;
  bool has_cpu_time = cpu_or_wall_sample && values.cpu_time_ns > 0;
  bool only_wall_time = cpu_or_wall_sample && values.cpu_time_ns == 0 && values.wall_time_ns > 0;

  if (cpu_or_wall_sample && state_label == NULL) rb_raise(rb_eRuntimeError, "BUG: Unexpected missing state_label");

  if (has_cpu_time) state_label->str = DDOG_CHARSLICE_C("had cpu");

  for (int i = captured_frames - 1; i >= 0; i--) {
    VALUE name, filename;
    int line;

    if (buffer->is_ruby_frame[i]) {
      last_ruby_frame = buffer->stack_buffer[i];
      last_ruby_line = buffer->lines_buffer[i];

      name = rb_profile_frame_base_label(buffer->stack_buffer[i]);
      filename = rb_profile_frame_path(buffer->stack_buffer[i]);
      line = buffer->lines_buffer[i];
    } else {
      name = ddtrace_rb_profile_frame_method_name(buffer->stack_buffer[i]);
      filename = NIL_P(last_ruby_frame) ? Qnil : rb_profile_frame_path(last_ruby_frame);
      line = last_ruby_line;
    }

    name = NIL_P(name) ? missing_string : name;
    filename = NIL_P(filename) ? missing_string : filename;

    ddog_CharSlice name_slice = char_slice_from_ruby_string(name);
    ddog_CharSlice filename_slice = char_slice_from_ruby_string(filename);

    bool top_of_the_stack = i == 0;

    // When there's only wall-time in a sample, this means that the thread was not active in the sampled period.
    //
    // We try to categorize what it was doing based on what we observe at the top of the stack. This is a very rough
    // approximation, and in the future we hope to replace this with a more accurate approach (such as using the
    // GVL instrumentation API.)
    if (top_of_the_stack && only_wall_time) {
      if (!buffer->is_ruby_frame[i]) {
        // We know that known versions of Ruby implement these using native code; thus if we find a method with the
        // same name that is not native code, we ignore it, as it's probably a user method that coincidentally
        // has the same name. Thus, even though "matching just by method name" is kinda weak,
        // "matching by method name" + is native code seems actually to be good enough for a lot of cases.

        if (CHARSLICE_EQUALS("sleep", name_slice)) { // Expected to be Kernel.sleep
          state_label->str  = DDOG_CHARSLICE_C("sleeping");
        } else if (CHARSLICE_EQUALS("select", name_slice)) { // Expected to be Kernel.select
          state_label->str  = DDOG_CHARSLICE_C("waiting");
        } else if (
            CHARSLICE_EQUALS("synchronize", name_slice) || // Expected to be Monitor/Mutex#synchronize
            CHARSLICE_EQUALS("lock", name_slice) ||        // Expected to be Mutex#lock
            CHARSLICE_EQUALS("join", name_slice)           // Expected to be Thread#join
        ) {
          state_label->str  = DDOG_CHARSLICE_C("blocked");
        } else if (CHARSLICE_EQUALS("wait_readable", name_slice)) { // Expected to be IO#wait_readable
          state_label->str  = DDOG_CHARSLICE_C("network");
        }
        #ifdef NO_PRIMITIVE_POP // Ruby < 3.2
          else if (CHARSLICE_EQUALS("pop", name_slice)) { // Expected to be Queue/SizedQueue#pop
            state_label->str  = DDOG_CHARSLICE_C("waiting");
          }
        #endif
      } else {
        #ifndef NO_PRIMITIVE_POP // Ruby >= 3.2
          // Unlike the above, Ruby actually treats this one specially and gives it a nice file name we can match on!
          if (CHARSLICE_EQUALS("pop", name_slice) && CHARSLICE_EQUALS("<internal:thread_sync>", filename_slice)) { // Expected to be Queue/SizedQueue#pop
            state_label->str  = DDOG_CHARSLICE_C("waiting");
          }
        #endif
      }
    }

    buffer->locations[i] = (ddog_prof_Location) {
      .function = (ddog_prof_Function) {
        .name = name_slice,
        .filename = filename_slice,
      },
      .line = line,
    };
  }

  // Used below; since we want to stack-allocate this, we must do it here rather than in maybe_add_placeholder_frames_omitted
  const int frames_omitted_message_size = sizeof(MAX_FRAMES_LIMIT_AS_STRING " frames omitted");
  char frames_omitted_message[frames_omitted_message_size];

  // If we filled up the buffer, some frames may have been omitted. In that case, we'll add a placeholder frame
  // with that info.
  if (captured_frames == (long) buffer->max_frames) {
    maybe_add_placeholder_frames_omitted(thread, buffer, frames_omitted_message, frames_omitted_message_size);
  }

  record_sample(
    recorder_instance,
    (ddog_prof_Slice_Location) {.ptr = record_buffer->locations, .len = captured_frames + extra_frames_in_record_buffer},
    values,
    labels
  );
}

static void maybe_add_placeholder_frames_omitted(VALUE thread, sampling_buffer* buffer, char *frames_omitted_message, int frames_omitted_message_size) {
  ptrdiff_t frames_omitted = stack_depth_for(thread) - buffer->max_frames;

  if (frames_omitted == 0) return; // Perfect fit!

  // The placeholder frame takes over a space, so if 10 frames were left out and we consume one other space for the
  // placeholder, then 11 frames are omitted in total
  frames_omitted++;

  snprintf(frames_omitted_message, frames_omitted_message_size, "%td frames omitted", frames_omitted);

  // Important note: `frames_omitted_message` MUST have a lifetime that is at least as long as the call to
  // `record_sample`. So be careful where it gets allocated. (We do have tests for this, at least!)
  ddog_CharSlice function_name = DDOG_CHARSLICE_C("");
  ddog_CharSlice function_filename = {.ptr = frames_omitted_message, .len = strlen(frames_omitted_message)};
  buffer->locations[buffer->max_frames - 1] = (ddog_prof_Location) {
    .function = (ddog_prof_Function) {.name = function_name, .filename = function_filename},
    .line = 0,
  };
}

// Our custom rb_profile_frames returning PLACEHOLDER_STACK_IN_NATIVE_CODE is equivalent to when the
// Ruby `Thread#backtrace` API returns an empty array: we know that a thread is alive but we don't know what it's doing:
//
// 1. It can be starting up
//    ```
//    > Thread.new { sleep }.backtrace
//    => [] # <-- note the thread hasn't actually started running sleep yet, we got there first
//    ```
// 2. It can be running native code
//    ```
//    > t = Process.detach(fork { sleep })
//    => #<Process::Waiter:0x00007ffe7285f7a0 run>
//    > t.backtrace
//    => [] # <-- this can happen even minutes later, e.g. it's not a race as in 1.
//    ```
//    This effect has been observed in threads created by the Iodine web server and the ffi gem,
//    see for instance https://github.com/ffi/ffi/pull/883 and https://github.com/DataDog/dd-trace-rb/pull/1719 .
//
// To give customers visibility into these threads, rather than reporting an empty stack, we replace the empty stack
// with one containing a placeholder frame, so that these threads are properly represented in the UX.
static void record_placeholder_stack_in_native_code(
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sampling_buffer *record_buffer,
  int extra_frames_in_record_buffer
) {
  ddog_CharSlice function_name = DDOG_CHARSLICE_C("");
  ddog_CharSlice function_filename = DDOG_CHARSLICE_C("In native code");
  buffer->locations[0] = (ddog_prof_Location) {
    .function = (ddog_prof_Function) {.name = function_name, .filename = function_filename},
    .line = 0
  };

  record_sample(
    recorder_instance,
    (ddog_prof_Slice_Location) {.ptr = record_buffer->locations, .len = 1 + extra_frames_in_record_buffer},
    values,
    labels
  );
}

sampling_buffer *sampling_buffer_new(unsigned int max_frames) {
  if (max_frames < 5) rb_raise(rb_eArgError, "Invalid max_frames: value must be >= 5");
  if (max_frames > MAX_FRAMES_LIMIT) rb_raise(rb_eArgError, "Invalid max_frames: value must be <= " MAX_FRAMES_LIMIT_AS_STRING);

  // Note: never returns NULL; if out of memory, it calls the Ruby out-of-memory handlers
  sampling_buffer* buffer = ruby_xcalloc(1, sizeof(sampling_buffer));

  buffer->max_frames = max_frames;

  buffer->stack_buffer  = ruby_xcalloc(max_frames, sizeof(VALUE));
  buffer->lines_buffer  = ruby_xcalloc(max_frames, sizeof(int));
  buffer->is_ruby_frame = ruby_xcalloc(max_frames, sizeof(bool));
  buffer->locations     = ruby_xcalloc(max_frames, sizeof(ddog_prof_Location));

  return buffer;
}

void sampling_buffer_free(sampling_buffer *buffer) {
  if (buffer == NULL) rb_raise(rb_eArgError, "sampling_buffer_free called with NULL buffer");

  ruby_xfree(buffer->stack_buffer);
  ruby_xfree(buffer->lines_buffer);
  ruby_xfree(buffer->is_ruby_frame);
  ruby_xfree(buffer->locations);

  ruby_xfree(buffer);
}
