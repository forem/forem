#include <errno.h>
#include <time.h>

#include "ruby_helpers.h"
#include "time_helpers.h"

// Safety: This function is assumed never to raise exceptions by callers when raise_on_failure == false
long retrieve_clock_as_ns(clockid_t clock_id, bool raise_on_failure) {
  struct timespec clock_value;

  if (clock_gettime(clock_id, &clock_value) != 0) {
    if (raise_on_failure) ENFORCE_SUCCESS_GVL(errno);
    return 0;
  }

  return clock_value.tv_nsec + SECONDS_AS_NS(clock_value.tv_sec);
}

long monotonic_wall_time_now_ns(bool raise_on_failure) { return retrieve_clock_as_ns(CLOCK_MONOTONIC, raise_on_failure); }
long system_epoch_time_now_ns(bool raise_on_failure)   { return retrieve_clock_as_ns(CLOCK_REALTIME,  raise_on_failure); }

// Design: The monotonic_to_system_epoch_state struct is kept somewhere by the caller, and MUST be initialized to
// MONOTONIC_TO_SYSTEM_EPOCH_INITIALIZER.
//
// This function is used by the ThreadContext collector to convert monotonic wall time timestamps which are used
// basically everywhere else in the codebase, into system epoch timestamps, which are needed by the timeline feature.
//
// There's a few ways we could have tackled this conversion, e.g. check the system clock on every call, or even
// use system clock timestamps elsewhere in the code.
// Using a system clock elsewhere has a few disadvantages (e.g. because it can move around if users adjust the system
// time). I also wanted to avoid calling system_epoch_time_now_ns(...) on every conversion.
//
// Thus I arrived at this solution: we calculate a delta between the monotonic clock and the system clock, and use
// that to convert the timestamps.
//
// To avoid the results of the system clock being off in cases where the system clock is adjusted while the profiler
// is running, every ~60 seconds of observed monotonic wall time we recalculate the delta. This means that worst case
// we'll have ~60 seconds of wrongly-timestamped data when the system clock jumps around, and in return we save the
// overhead of having to look up the system clock on every call to this function.
long monotonic_to_system_epoch_ns(monotonic_to_system_epoch_state *state, long monotonic_wall_time_ns) {
  bool reference_needs_update =
    (state->system_epoch_ns_reference == INVALID_TIME) ||
    (state->delta_to_epoch_ns + monotonic_wall_time_ns > state->system_epoch_ns_reference + SECONDS_AS_NS(60));

  if (reference_needs_update) {
    state->system_epoch_ns_reference = system_epoch_time_now_ns(RAISE_ON_FAILURE);
    long current_monotonic_wall_time_ns = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);

    state->delta_to_epoch_ns = state->system_epoch_ns_reference - current_monotonic_wall_time_ns;
  }

  return state->delta_to_epoch_ns + monotonic_wall_time_ns;
}
