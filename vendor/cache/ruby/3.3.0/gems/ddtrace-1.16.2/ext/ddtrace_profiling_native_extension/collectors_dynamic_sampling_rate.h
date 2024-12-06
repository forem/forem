#pragma once

#include <stdatomic.h>
#include <stdbool.h>

typedef struct {
  atomic_long next_sample_after_monotonic_wall_time_ns;
} dynamic_sampling_rate_state;

void dynamic_sampling_rate_init(dynamic_sampling_rate_state *state);
void dynamic_sampling_rate_reset(dynamic_sampling_rate_state *state);
uint64_t dynamic_sampling_rate_get_sleep(dynamic_sampling_rate_state *state, long current_monotonic_wall_time_ns);
bool dynamic_sampling_rate_should_sample(dynamic_sampling_rate_state *state, long wall_time_ns_before_sample);
void dynamic_sampling_rate_after_sample(dynamic_sampling_rate_state *state, long wall_time_ns_after_sample, uint64_t sampling_time_ns);
