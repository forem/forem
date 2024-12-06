/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_CALL_TREE_H__
#define __RP_CALL_TREE_H__

#include "ruby_prof.h"
#include "rp_measurement.h"
#include "rp_method.h"

extern VALUE cRpCallTree;

/* Callers and callee information for a method. */
typedef struct prof_call_tree_t
{
    prof_owner_t owner;
    prof_method_t* method;
    struct prof_call_tree_t* parent;
    st_table* children;             /* Call infos that this call info calls */
    prof_measurement_t* measurement;
    VALUE object;

    int visits;                             /* Current visits on the stack */

    unsigned int source_line;
    VALUE source_file;
} prof_call_tree_t;

prof_call_tree_t* prof_call_tree_create(prof_method_t* method, prof_call_tree_t* parent, VALUE source_file, int source_line);
prof_call_tree_t* prof_call_tree_copy(prof_call_tree_t* other);
void prof_call_tree_merge_internal(prof_call_tree_t* destination, prof_call_tree_t* other, st_table* method_table);
void prof_call_tree_mark(void* data);
prof_call_tree_t* call_tree_table_lookup(st_table* table, st_data_t key);

void prof_call_tree_add_parent(prof_call_tree_t* self, prof_call_tree_t* parent);
void prof_call_tree_add_child(prof_call_tree_t* self, prof_call_tree_t* child);

uint32_t prof_call_tree_figure_depth(prof_call_tree_t* call_tree);
VALUE prof_call_tree_methods(prof_call_tree_t* call_tree);

prof_call_tree_t* prof_get_call_tree(VALUE self);
VALUE prof_call_tree_wrap(prof_call_tree_t* call_tree);
void prof_call_tree_free(prof_call_tree_t* call_tree);

void rp_init_call_tree(void);

#endif //__RP_CALL_TREE_H__
