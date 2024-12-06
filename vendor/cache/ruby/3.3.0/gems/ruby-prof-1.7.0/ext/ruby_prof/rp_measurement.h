/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __rp_measurementMENT_H__
#define __rp_measurementMENT_H__

#include "ruby_prof.h"

extern VALUE mMeasure;

typedef double (*get_measurement)(rb_trace_arg_t* trace_arg);

typedef enum
{
    MEASURE_WALL_TIME,
    MEASURE_PROCESS_TIME,
    MEASURE_ALLOCATIONS,
    MEASURE_MEMORY
} prof_measure_mode_t;

typedef struct prof_measurer_t
{
    get_measurement measure;
    prof_measure_mode_t mode;
    double multiplier;
    bool track_allocations;
} prof_measurer_t;

/* Callers and callee information for a method. */
typedef struct prof_measurement_t
{
    prof_owner_t owner;
    double total_time;
    double self_time;
    double wait_time;
    int called;
    VALUE object;
} prof_measurement_t;

prof_measurer_t* prof_measurer_create(prof_measure_mode_t measure, bool track_allocations);
double prof_measure(prof_measurer_t* measurer, rb_trace_arg_t* trace_arg);

prof_measurement_t* prof_measurement_create(void);
prof_measurement_t* prof_measurement_copy(prof_measurement_t* other);
void prof_measurement_free(prof_measurement_t* measurement);
VALUE prof_measurement_wrap(prof_measurement_t* measurement);
prof_measurement_t* prof_get_measurement(VALUE self);
void prof_measurement_mark(void* data);
void prof_measurement_merge_internal(prof_measurement_t* destination, prof_measurement_t* other);

void rp_init_measure(void);

#endif //__rp_measurementMENT_H__
