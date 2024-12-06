/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

   /* :nodoc: */
#include "rp_measurement.h"

#if defined(__APPLE__)
#include <mach/mach_time.h>
#elif !defined(_WIN32)
#include <time.h>
#endif

static VALUE cMeasureWallTime;

static double measure_wall_time(rb_trace_arg_t* trace_arg)
{
#if defined(_WIN32)
    LARGE_INTEGER time;
    QueryPerformanceCounter(&time);
    return (double)time.QuadPart;
#elif defined(__APPLE__)
    return mach_absolute_time();// * (uint64_t)mach_timebase.numer / (uint64_t)mach_timebase.denom;
#elif defined(__linux__)
    struct timespec tv;
    clock_gettime(CLOCK_MONOTONIC, &tv);
    return tv.tv_sec + (tv.tv_nsec / 1000000000.0);
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (tv.tv_usec / 1000000.0);
#endif
}

static double multiplier_wall_time(void)
{
#if defined(_WIN32)
    LARGE_INTEGER frequency;
    QueryPerformanceFrequency(&frequency);
    return 1.0 / frequency.QuadPart;
#elif defined(__APPLE__)
    mach_timebase_info_data_t mach_timebase;
    mach_timebase_info(&mach_timebase);
    return (uint64_t)mach_timebase.numer / (uint64_t)mach_timebase.denom / 1000000000.0;
#else
    return 1.0;
#endif
}

prof_measurer_t* prof_measurer_wall_time(bool track_allocations)
{
    prof_measurer_t* measure = ALLOC(prof_measurer_t);
    measure->mode = MEASURE_WALL_TIME;
    measure->measure = measure_wall_time;
    measure->multiplier = multiplier_wall_time();
    measure->track_allocations = track_allocations;
    return measure;
}

void rp_init_measure_wall_time(void)
{
    rb_define_const(mProf, "WALL_TIME", INT2NUM(MEASURE_WALL_TIME));

    cMeasureWallTime = rb_define_class_under(mMeasure, "WallTime", rb_cObject);
}
