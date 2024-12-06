/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

   /* ruby-prof tracks the time spent executing every method in ruby programming.
      The main players are:

        profile_t         - This represents 1 profile.
        thread_data_t     - Stores data about a single thread.
        prof_stack_t      - The method call stack in a particular thread
        prof_method_t     - Profiling information about each method
        prof_call_tree_t  - Keeps track a method's callers and callees.

     The final result is an instance of a profile object which has a hash table of
     thread_data_t, keyed on the thread id.  Each thread in turn has a hash table
     of prof_method_t, keyed on the method id.  A hash table is used for quick
     look up when doing a profile.  However, it is exposed to Ruby as an array.

     Each prof_method_t has two hash tables, parent and children, of prof_call_tree_t.
     These objects keep track of a method's callers (who called the method) and its
     callees (who the method called).  These are keyed the method id, but once again,
     are exposed to Ruby as arrays.  Each prof_call_into_t maintains a pointer to the
     caller or callee method, thereby making it easy to navigate through the call
     hierarchy in ruby - which is very helpful for creating call graphs.
   */

#include "ruby_prof.h"

#include "rp_allocation.h"
#include "rp_measurement.h"
#include "rp_method.h"
#include "rp_call_tree.h"
#include "rp_call_trees.h"
#include "rp_profile.h"
#include "rp_stack.h"
#include "rp_thread.h"

VALUE mProf;

void Init_ruby_prof(void)
{
    mProf = rb_define_module("RubyProf");

    rp_init_allocation();
    rp_init_call_tree();
    rp_init_call_trees();
    rp_init_measure();
    rp_init_method_info();
    rp_init_profile();
    rp_init_thread();
}
