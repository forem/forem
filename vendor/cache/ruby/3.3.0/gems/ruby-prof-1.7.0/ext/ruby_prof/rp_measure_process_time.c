/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_measurement.h"
#include <time.h>

static VALUE cMeasureProcessTime;

static double measure_process_time(rb_trace_arg_t* trace_arg)
{
#if defined(_WIN32)
    FILETIME  createTime;
    FILETIME  exitTime;
    FILETIME  kernelTime;
    FILETIME  userTime;

    ULARGE_INTEGER kernelTimeInt;
    ULARGE_INTEGER userTimeInt;

    GetProcessTimes(GetCurrentProcess(), &createTime, &exitTime, &kernelTime, &userTime);

    kernelTimeInt.LowPart = kernelTime.dwLowDateTime;
    kernelTimeInt.HighPart = kernelTime.dwHighDateTime;
    userTimeInt.LowPart = userTime.dwLowDateTime;
    userTimeInt.HighPart = userTime.dwHighDateTime;

    return (double)(kernelTimeInt.QuadPart + userTimeInt.QuadPart);
#elif !defined(CLOCK_PROCESS_CPUTIME_ID)
    #include <sys/resource.h>
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    return usage.ru_stime.tv_sec + usage.ru_utime.tv_sec + ((usage.ru_stime.tv_usec + usage.ru_utime.tv_usec) / 1000000.0);
#else
    struct timespec clock;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &clock);
    return clock.tv_sec + (clock.tv_nsec / 1000000000.0);
#endif
}

static double multiplier_process_time(void)
{
#if defined(_WIN32)
    // Times are in 100-nanosecond time units.  So instead of 10-9 use 10-7
    return 1.0 / 10000000.0;
#else
    return 1.0;
#endif
}

prof_measurer_t* prof_measurer_process_time(bool track_allocations)
{
    prof_measurer_t* measure = ALLOC(prof_measurer_t);
    measure->mode = MEASURE_PROCESS_TIME;
    measure->measure = measure_process_time;
    measure->multiplier = multiplier_process_time();
    measure->track_allocations = track_allocations;
    return measure;
}

void rp_init_measure_process_time(void)
{
    rb_define_const(mProf, "CLOCKS_PER_SEC", INT2NUM(CLOCKS_PER_SEC));
    rb_define_const(mProf, "PROCESS_TIME", INT2NUM(MEASURE_PROCESS_TIME));

    cMeasureProcessTime = rb_define_class_under(mMeasure, "ProcessTime", rb_cObject);
}
