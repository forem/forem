/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_PROF_H__
#define __RUBY_PROF_H__

#include <ruby.h>
#include <ruby/debug.h>
#include <stdio.h>
#include <stdbool.h>

#ifndef rb_st_lookup
#define rb_st_foreach st_foreach
#define rb_st_free_table st_free_table
#define rb_st_init_numtable st_init_numtable
#define rb_st_insert st_insert
#define rb_st_lookup st_lookup
#endif


extern VALUE mProf;

// This method is not exposed in Ruby header files - at least not as of Ruby 2.6.3 :(
extern size_t rb_obj_memsize_of(VALUE);

typedef enum
{
  OWNER_UNKNOWN = 0,
  OWNER_RUBY = 1,
  OWNER_C = 2
} prof_owner_t;


#endif //__RUBY_PROF_H__
