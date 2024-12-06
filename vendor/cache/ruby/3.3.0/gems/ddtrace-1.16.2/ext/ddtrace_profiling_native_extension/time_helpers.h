#pragma once

#define SECONDS_AS_NS(value) (value * 1000 * 1000 * 1000L)
#define MILLIS_AS_NS(value) (value * 1000 * 1000L)

#define RAISE_ON_FAILURE true
#define DO_NOT_RAISE_ON_FAILURE false

#define INVALID_TIME -1

typedef struct {
  long system_epoch_ns_reference;
  long delta_to_epoch_ns;
} monotonic_to_system_epoch_state;

#define MONOTONIC_TO_SYSTEM_EPOCH_INITIALIZER {.system_epoch_ns_reference = INVALID_TIME, .delta_to_epoch_ns = INVALID_TIME}

// Safety: This function is assumed never to raise exceptions by callers when raise_on_failure == false
long monotonic_wall_time_now_ns(bool raise_on_failure);

// Safety: This function is assumed never to raise exceptions by callers when raise_on_failure == false
long system_epoch_time_now_ns(bool raise_on_failure);

long monotonic_to_system_epoch_ns(monotonic_to_system_epoch_state *state, long monotonic_wall_time_ns);
