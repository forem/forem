/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_PROFILE_H__
#define __RP_PROFILE_H__

#include "ruby_prof.h"
#include "rp_measurement.h"
#include "rp_thread.h"

extern VALUE cProfile;

typedef struct prof_profile_t
{
    VALUE object;
    VALUE running;
    VALUE paused;

    prof_measurer_t* measurer;

    VALUE tracepoints;

    st_table* threads_tbl;
    st_table* exclude_threads_tbl;
    st_table* include_threads_tbl;
    st_table* exclude_methods_tbl;
    thread_data_t* last_thread_data;
    double measurement_at_pause_resume;
    bool allow_exceptions;
} prof_profile_t;

void rp_init_profile(void);
prof_profile_t* prof_get_profile(VALUE self);


#endif //__RP_PROFILE_H__
