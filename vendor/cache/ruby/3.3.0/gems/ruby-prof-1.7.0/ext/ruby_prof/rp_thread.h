/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_THREAD__
#define __RP_THREAD__

#include "ruby_prof.h"
#include "rp_stack.h"

/* Profiling information for a thread. */
typedef struct thread_data_t
{
    prof_owner_t owner;               /* Who owns this object */
    VALUE object;                     /* Cache to wrapped object */
    VALUE fiber;                      /* Fiber */
    prof_stack_t* stack;              /* Stack of frames */
    bool trace;                       /* Are we tracking this thread */
    prof_call_tree_t* call_tree;      /* The root of the call tree*/
    VALUE thread_id;                  /* Thread id */
    VALUE fiber_id;                   /* Fiber id */
    VALUE methods;                    /* Array of RubyProf::MethodInfo */
    st_table* method_table;           /* Methods called in the thread */
} thread_data_t;

void rp_init_thread(void);
st_table* threads_table_create(void);
thread_data_t* threads_table_lookup(void* profile, VALUE fiber);
thread_data_t* threads_table_insert(void* profile, VALUE fiber);
void threads_table_free(st_table* table);

thread_data_t* prof_get_thread(VALUE self);
VALUE prof_thread_wrap(thread_data_t* thread);
void prof_thread_mark(void* data);

void switch_thread(void* profile, thread_data_t* thread_data, double measurement);
int pause_thread(st_data_t key, st_data_t value, st_data_t data);
int unpause_thread(st_data_t key, st_data_t value, st_data_t data);

#endif //__RP_THREAD__
