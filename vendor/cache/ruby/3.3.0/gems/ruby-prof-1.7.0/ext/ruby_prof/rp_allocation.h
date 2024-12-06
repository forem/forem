/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef _RP_ALLOCATION_
#define _RP_ALLOCATION_

#include "ruby_prof.h"

typedef struct prof_allocation_t
{
    st_data_t key;                    /* Key in hash table */
    unsigned int klass_flags;         /* Information about the type of class */
    VALUE klass;                      /* Klass that was created */
    VALUE klass_name;                 /* Name of the class that was created */
    VALUE source_file;                /* Line number where allocation happens */
    int source_line;                  /* Line number where allocation happens */
    int count;                        /* Number of allocations */
    size_t memory;                    /* Amount of allocated memory */
    VALUE object;                     /* Cache to wrapped object */
} prof_allocation_t;

// Allocation (prof_allocation_t*)
void rp_init_allocation(void);
prof_allocation_t* prof_allocate_increment(st_table* allocations_table, rb_trace_arg_t* trace_arg);

// Allocations (st_table*)
st_table* prof_allocations_create(void);
VALUE prof_allocations_wrap(st_table* allocations_table);
void prof_allocations_unwrap(st_table* allocations_table, VALUE allocations);
void prof_allocations_mark(st_table* allocations_table);
void prof_allocations_free(st_table* table);

#endif //_RP_ALLOCATION_
