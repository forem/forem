/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* Document-class: RubyProf::Thread

The Thread class contains profile results for a single fiber (note a Ruby thread can run multiple fibers).
You cannot create an instance of RubyProf::Thread, instead you access it from a RubyProf::Profile object.

  profile = RubyProf::Profile.profile do
              ...
            end

  profile.threads.each do |thread|
    thread.root_methods.sort.each do |method|
      puts method.total_time
    end
  end */

#include "rp_thread.h"
#include "rp_profile.h"

VALUE cRpThread;

// ======   thread_data_t  ======
thread_data_t* thread_data_create(void)
{
    thread_data_t* result = ALLOC(thread_data_t);
    result->owner = OWNER_C;
    result->stack = prof_stack_create();
    result->method_table = method_table_create();
    result->call_tree = NULL;
    result->object = Qnil;
    result->methods = Qnil;
    result->fiber_id = Qnil;
    result->thread_id = Qnil;
    result->trace = true;
    result->fiber = Qnil;
    return result;
}

static int mark_methods(st_data_t key, st_data_t value, st_data_t result)
{
    prof_method_t* method = (prof_method_t*)value;
    prof_method_mark(method);
    return ST_CONTINUE;
}

size_t prof_thread_size(const void* data)
{
    return sizeof(thread_data_t);
}

void prof_thread_mark(void* data)
{
    if (!data)
        return;

    thread_data_t* thread = (thread_data_t*)data;

    if (thread->object != Qnil)
        rb_gc_mark_movable(thread->object);

    rb_gc_mark(thread->fiber);

    if (thread->methods != Qnil)
        rb_gc_mark_movable(thread->methods);

    if (thread->fiber_id != Qnil)
        rb_gc_mark_movable(thread->fiber_id);

    if (thread->thread_id != Qnil)
        rb_gc_mark_movable(thread->thread_id);

    if (thread->call_tree)
        prof_call_tree_mark(thread->call_tree);

    rb_st_foreach(thread->method_table, mark_methods, 0);
}

void prof_thread_compact(void* data)
{
    thread_data_t* thread = (thread_data_t*)data;
    thread->object = rb_gc_location(thread->object);
    thread->methods = rb_gc_location(thread->methods);
    thread->fiber_id = rb_gc_location(thread->fiber_id);
    thread->thread_id = rb_gc_location(thread->thread_id);
}

static void prof_thread_free(thread_data_t* thread_data)
{
    /* Has this method object been accessed by Ruby?  If
       yes then set its data to nil to avoid a segmentation fault on the next mark and sweep. */
    if (thread_data->object != Qnil)
    {
        RTYPEDDATA(thread_data->object)->data = NULL;
        thread_data->object = Qnil;
    }

    method_table_free(thread_data->method_table);

    if (thread_data->call_tree)
        prof_call_tree_free(thread_data->call_tree);

    prof_stack_free(thread_data->stack);

    xfree(thread_data);
}

void prof_thread_ruby_gc_free(void* data)
{
    thread_data_t* thread_data = (thread_data_t*)data;

    if (!thread_data)
    {
        // Object has already been freed by C code
        return;
    }
    else if (thread_data->owner == OWNER_RUBY)
    {
        // Ruby owns this object, we need to free the underlying C struct
        prof_thread_free(thread_data);
    }
    else
    {
        // The Ruby object is being freed, but not the underlying C structure. So unlink the two.
        thread_data->object = Qnil;
    }
}

static const rb_data_type_t thread_type =
{
    .wrap_struct_name = "ThreadInfo",
    .function =
    {
        .dmark = prof_thread_mark,
        .dfree = prof_thread_ruby_gc_free,
        .dsize = prof_thread_size,
        .dcompact = prof_thread_compact
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_thread_wrap(thread_data_t* thread)
{
    if (thread->object == Qnil)
    {
        thread->object = TypedData_Wrap_Struct(cRpThread, &thread_type, thread);
    }
    return thread->object;
}

static VALUE prof_thread_allocate(VALUE klass)
{
    thread_data_t* thread_data = thread_data_create();
    thread_data->owner = OWNER_RUBY;
    thread_data->object = prof_thread_wrap(thread_data);
    return thread_data->object;
}

thread_data_t* prof_get_thread(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    thread_data_t* result = RTYPEDDATA_DATA(self);
    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Thread instance has already been freed, likely because its profile has been freed.");

    return result;
}

// ======   Thread Table  ======
// The thread table is hash keyed on ruby fiber_id that stores instances of thread_data_t.

st_table* threads_table_create(void)
{
    return rb_st_init_numtable();
}

static int thread_table_free_iterator(st_data_t key, st_data_t value, st_data_t dummy)
{
    prof_thread_free((thread_data_t*)value);
    return ST_CONTINUE;
}

void threads_table_free(st_table* table)
{
    rb_st_foreach(table, thread_table_free_iterator, 0);
    rb_st_free_table(table);
}

thread_data_t* threads_table_lookup(void* prof, VALUE fiber)
{
    prof_profile_t* profile = prof;
    thread_data_t* result = NULL;
    st_data_t val;

    VALUE fiber_id = rb_obj_id(fiber);
    if (rb_st_lookup(profile->threads_tbl, fiber_id, &val))
    {
        result = (thread_data_t*)val;
    }

    return result;
}

thread_data_t* threads_table_insert(void* prof, VALUE fiber)
{
    prof_profile_t* profile = prof;
    thread_data_t* result = thread_data_create();
    VALUE thread = rb_thread_current();

    result->fiber = fiber;
    result->fiber_id = rb_obj_id(fiber);
    result->thread_id = rb_obj_id(thread);
    rb_st_insert(profile->threads_tbl, (st_data_t)result->fiber_id, (st_data_t)result);

    // Are we tracing this thread?
    if (profile->include_threads_tbl && !rb_st_lookup(profile->include_threads_tbl, thread, 0))
    {
        result->trace = false;
    }
    else if (profile->exclude_threads_tbl && rb_st_lookup(profile->exclude_threads_tbl, thread, 0))
    {
        result->trace = false;
    }
    else
    {
        result->trace = true;
    }

    return result;
}

// ======   Profiling Methods  ======
void switch_thread(void* prof, thread_data_t* thread_data, double measurement)
{
    prof_profile_t* profile = prof;

    /* Get current frame for this thread */
    prof_frame_t* frame = prof_frame_current(thread_data->stack);
    if (frame)
    {
        frame->wait_time += measurement - frame->switch_time;
        frame->switch_time = 0;
    }

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (profile->last_thread_data)
    {
        prof_frame_t* last_frame = prof_frame_current(profile->last_thread_data->stack);
        if (last_frame)
            last_frame->switch_time = measurement;
    }

    profile->last_thread_data = thread_data;
}

int pause_thread(st_data_t key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;

    prof_frame_t* frame = prof_frame_current(thread_data->stack);
    prof_frame_pause(frame, profile->measurement_at_pause_resume);

    return ST_CONTINUE;
}

int unpause_thread(st_data_t key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;

    prof_frame_t* frame = prof_frame_current(thread_data->stack);
    prof_frame_unpause(frame, profile->measurement_at_pause_resume);

    return ST_CONTINUE;
}

// ======   Helper Methods  ======
static int collect_methods(st_data_t key, st_data_t value, st_data_t result)
{
    /* Called for each method stored in a thread's method table.
       We want to store the method info information into an array.*/
    VALUE methods = (VALUE)result;
    prof_method_t* method = (prof_method_t*)value;
    rb_ary_push(methods, prof_method_wrap(method));

    return ST_CONTINUE;
}

// ======   RubyProf::Thread  ======
/* call-seq:
   new(call_tree, thread, fiber) -> thread

Creates a new RubyProf thread instance. +call_tree+ is the root call_tree instance,
+thread+ is a reference to a Ruby thread and +fiber+ is a reference to a Ruby fiber.*/
static VALUE prof_thread_initialize(VALUE self, VALUE call_tree, VALUE thread, VALUE fiber)
{
  thread_data_t* thread_ptr = prof_get_thread(self);

  // This call tree must now be managed by C
  thread_ptr->call_tree = prof_get_call_tree(call_tree);
  thread_ptr->call_tree->owner = OWNER_C;

  thread_ptr->fiber = fiber;
  thread_ptr->fiber_id = rb_obj_id(fiber);
  thread_ptr->thread_id = rb_obj_id(thread);

  // Add methods from call trees into thread methods table
  VALUE methods = prof_call_tree_methods(thread_ptr->call_tree);
  for (int i = 0; i < rb_array_len(methods); i++)
  {
      VALUE method = rb_ary_entry(methods, i);
      prof_method_t* method_ptr = prof_get_method(method);
      method_table_insert(thread_ptr->method_table, method_ptr->key, method_ptr);
  }

  return self;
}

/* call-seq:
   id -> number

Returns the thread id of this thread. */
static VALUE prof_thread_id(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return thread->thread_id;
}

/* call-seq:
   fiber_id -> number

Returns the fiber id of this thread. */
static VALUE prof_fiber_id(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return thread->fiber_id;
}

/* call-seq:
   call_tree -> CallTree

Returns the root call tree. */
static VALUE prof_call_tree(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return prof_call_tree_wrap(thread->call_tree);
}

/* call-seq:
   methods -> [RubyProf::MethodInfo]

Returns an array of methods that were called from this
thread during program execution. */
static VALUE prof_thread_methods(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    if (thread->methods == Qnil)
    {
        thread->methods = rb_ary_new();
        rb_st_foreach(thread->method_table, collect_methods, thread->methods);
    }
    return thread->methods;
}

static VALUE prof_thread_merge(VALUE self, VALUE other)
{
  thread_data_t* self_ptr = prof_get_thread(self);
  thread_data_t* other_ptr = prof_get_thread(other);
  prof_method_table_merge(self_ptr->method_table, other_ptr->method_table);
  prof_call_tree_merge_internal(self_ptr->call_tree, other_ptr->call_tree, self_ptr->method_table);

  // Reset method cache since it just changed
  self_ptr->methods = Qnil;

  return other;
}

/* :nodoc: */
static VALUE prof_thread_dump(VALUE self)
{
    thread_data_t* thread_data = RTYPEDDATA_DATA(self);

    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("owner")), INT2FIX(thread_data->owner));
    rb_hash_aset(result, ID2SYM(rb_intern("fiber_id")), thread_data->fiber_id);
    rb_hash_aset(result, ID2SYM(rb_intern("methods")), prof_thread_methods(self));
    rb_hash_aset(result, ID2SYM(rb_intern("call_tree")), prof_call_tree(self));

    return result;
}

/* :nodoc: */
static VALUE prof_thread_load(VALUE self, VALUE data)
{
    thread_data_t* thread_data = RTYPEDDATA_DATA(self);

    thread_data->owner = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("owner"))));

    VALUE call_tree = rb_hash_aref(data, ID2SYM(rb_intern("call_tree")));
    thread_data->call_tree = prof_get_call_tree(call_tree);

    thread_data->fiber_id = rb_hash_aref(data, ID2SYM(rb_intern("fiber_id")));

    VALUE methods = rb_hash_aref(data, ID2SYM(rb_intern("methods")));
    for (int i = 0; i < rb_array_len(methods); i++)
    {
        VALUE method = rb_ary_entry(methods, i);
        prof_method_t* method_data = RTYPEDDATA_DATA(method);
        method_table_insert(thread_data->method_table, method_data->key, method_data);
    }

    return data;
}

void rp_init_thread(void)
{
    cRpThread = rb_define_class_under(mProf, "Thread", rb_cObject);
    rb_define_alloc_func(cRpThread, prof_thread_allocate);
    rb_define_method(cRpThread, "initialize", prof_thread_initialize, 3);

    rb_define_method(cRpThread, "id", prof_thread_id, 0);
    rb_define_method(cRpThread, "call_tree", prof_call_tree, 0);
    rb_define_method(cRpThread, "fiber_id", prof_fiber_id, 0);
    rb_define_method(cRpThread, "methods", prof_thread_methods, 0);
    rb_define_method(cRpThread, "merge!", prof_thread_merge, 1);
    rb_define_method(cRpThread, "_dump_data", prof_thread_dump, 0);
    rb_define_method(cRpThread, "_load_data", prof_thread_load, 1);
}
