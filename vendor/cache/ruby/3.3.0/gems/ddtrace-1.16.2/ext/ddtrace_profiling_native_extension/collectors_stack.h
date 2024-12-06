#pragma once

#include <datadog/profiling.h>

#include "stack_recorder.h"

typedef struct sampling_buffer sampling_buffer;

typedef enum { SAMPLE_REGULAR, SAMPLE_IN_GC } sample_type;

void sample_thread(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  sample_type type
);
sampling_buffer *sampling_buffer_new(unsigned int max_frames);
void sampling_buffer_free(sampling_buffer *buffer);
