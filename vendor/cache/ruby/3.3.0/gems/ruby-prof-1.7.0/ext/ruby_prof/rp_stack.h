/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_STACK__
#define __RP_STACK__

#include "ruby_prof.h"
#include "rp_call_tree.h"

   /* Temporary object that maintains profiling information
      for active methods.  They are created and destroyed
      as the program moves up and down its stack. */
typedef struct prof_frame_t
{
    /* Caching prof_method_t values significantly
       increases performance. */
    prof_call_tree_t* call_tree;

    VALUE source_file;
    unsigned int source_line;

    double start_time;
    double switch_time;  /* Time at switch to different thread */
    double wait_time;
    double child_time;
    double pause_time; // Time pause() was initiated
    double dead_time; // Time to ignore (i.e. total amount of time between pause/resume blocks)
} prof_frame_t;

#define prof_frame_is_paused(f) (f->pause_time >= 0)
#define prof_frame_is_unpaused(f) (f->pause_time < 0)

void prof_frame_pause(prof_frame_t*, double current_measurement);
void prof_frame_unpause(prof_frame_t*, double current_measurement);

/* Current stack of active methods.*/
typedef struct prof_stack_t
{
    prof_frame_t* start;
    prof_frame_t* end;
    prof_frame_t* ptr;
} prof_stack_t;

prof_stack_t* prof_stack_create(void);
void prof_stack_free(prof_stack_t* stack);

prof_frame_t* prof_frame_current(prof_stack_t* stack);
prof_frame_t* prof_frame_push(prof_stack_t* stack, prof_call_tree_t* call_tree, double measurement, bool paused);
prof_frame_t* prof_frame_unshift(prof_stack_t* stack, prof_call_tree_t* parent_call_tree, prof_call_tree_t* call_tree, double measurement);
prof_frame_t* prof_frame_pop(prof_stack_t* stack, double measurement);
prof_method_t* prof_find_method(prof_stack_t* stack, VALUE source_file, int source_line);

#endif //__RP_STACK__
