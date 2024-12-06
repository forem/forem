/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_tree.h"
#include "rp_call_trees.h"
#include "rp_thread.h"

VALUE cRpCallTree;

/* =======  prof_call_tree_t   ========*/
prof_call_tree_t* prof_call_tree_create(prof_method_t* method, prof_call_tree_t* parent, VALUE source_file, int source_line)
{
    prof_call_tree_t* result = ALLOC(prof_call_tree_t);
    result->owner = OWNER_C;
    result->method = method;
    result->parent = parent;
    result->object = Qnil;
    result->visits = 0;
    result->source_line = source_line;
    result->source_file = source_file;
    result->children = rb_st_init_numtable();
    result->measurement = prof_measurement_create();

    return result;
}

prof_call_tree_t* prof_call_tree_copy(prof_call_tree_t* other)
{
    prof_call_tree_t* result = prof_call_tree_create(other->method, other->parent, other->source_file, other->source_line);
    result->measurement = prof_measurement_copy(other->measurement);

    return result;
}

static int prof_call_tree_collect_children(st_data_t key, st_data_t value, st_data_t result)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    VALUE arr = (VALUE)result;
    rb_ary_push(arr, prof_call_tree_wrap(call_tree));
    return ST_CONTINUE;
}

static int prof_call_tree_mark_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    rb_st_foreach(call_tree->children, prof_call_tree_mark_children, data);
    prof_call_tree_mark(call_tree);
    return ST_CONTINUE;
}

void prof_call_tree_mark(void* data)
{
    if (!data)
        return;

    prof_call_tree_t* call_tree = (prof_call_tree_t*)data;

    if (call_tree->object != Qnil)
        rb_gc_mark_movable(call_tree->object);

    if (call_tree->source_file != Qnil)
        rb_gc_mark(call_tree->source_file);

    prof_method_mark(call_tree->method);
    prof_measurement_mark(call_tree->measurement);

    // Recurse down through the whole call tree but only from the top node
    // to avoid calling mark over and over and over.
    if (!call_tree->parent)
        rb_st_foreach(call_tree->children, prof_call_tree_mark_children, 0);
}

void prof_call_tree_compact(void* data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)data;
    call_tree->object = rb_gc_location(call_tree->object);
}

static int prof_call_tree_free_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    prof_call_tree_free(call_tree);
    return ST_CONTINUE;
}

void prof_call_tree_free(prof_call_tree_t* call_tree_data)
{
    /* Has this call info object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (call_tree_data->object != Qnil)
    {
        RTYPEDDATA(call_tree_data->object)->data = NULL;
        call_tree_data->object = Qnil;
    }

    // Free children
    rb_st_foreach(call_tree_data->children, prof_call_tree_free_children, 0);
    rb_st_free_table(call_tree_data->children);

    // Free measurement
    prof_measurement_free(call_tree_data->measurement);

    // Finally free self
    xfree(call_tree_data);
}

static void prof_call_tree_ruby_gc_free(void* data)
{
  prof_call_tree_t* call_tree = (prof_call_tree_t*)data;

  if (!call_tree)
  {
    // Object has already been freed by C code
    return;
  }
  else if (call_tree->owner == OWNER_RUBY)
  {
    // Ruby owns this object, we need to free the underlying C struct
    prof_call_tree_free(call_tree);
  }
  else
  {
    // The Ruby object is being freed, but not the underlying C structure. So unlink the two.
    call_tree->object = Qnil;
  }
}

size_t prof_call_tree_size(const void* data)
{
    return sizeof(prof_call_tree_t);
}

static const rb_data_type_t call_tree_type =
{
    .wrap_struct_name = "CallTree",
    .function =
    {
        .dmark = prof_call_tree_mark,
        .dfree = prof_call_tree_ruby_gc_free,
        .dsize = prof_call_tree_size,
        .dcompact = prof_call_tree_compact
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_call_tree_wrap(prof_call_tree_t* call_tree)
{
    if (call_tree->object == Qnil)
    {
        call_tree->object = TypedData_Wrap_Struct(cRpCallTree, &call_tree_type, call_tree);
    }
    return call_tree->object;
}

static VALUE prof_call_tree_allocate(VALUE klass)
{
    prof_call_tree_t* call_tree = prof_call_tree_create(NULL, NULL, Qnil, 0);
    // This object is being created by Ruby
    call_tree->owner = OWNER_RUBY;
    call_tree->object = prof_call_tree_wrap(call_tree);
    return call_tree->object;
}

prof_call_tree_t* prof_get_call_tree(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_call_tree_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::CallTree instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* =======  Call Tree Table   ========*/
static size_t call_tree_table_insert(st_table* table, st_data_t key, prof_call_tree_t* val)
{
    return rb_st_insert(table, (st_data_t)key, (st_data_t)val);
}

prof_call_tree_t* call_tree_table_lookup(st_table* table, st_data_t key)
{
    st_data_t val;
    if (rb_st_lookup(table, (st_data_t)key, &val))
    {
        return (prof_call_tree_t*)val;
    }
    else
    {
        return NULL;
    }
}

uint32_t prof_call_tree_figure_depth(prof_call_tree_t* call_tree)
{
    uint32_t result = 0;

    while (call_tree->parent)
    {
        result++;
        call_tree = call_tree->parent;
    }

    return result;
}

int prof_call_tree_collect_methods(st_data_t key, st_data_t value, st_data_t result)
{
  prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
  VALUE arr = (VALUE)result;
  rb_ary_push(arr, prof_method_wrap(call_tree->method));

  rb_st_foreach(call_tree->children, prof_call_tree_collect_methods, result);
  return ST_CONTINUE;
};

VALUE prof_call_tree_methods(prof_call_tree_t* call_tree)
{
    VALUE result = rb_ary_new();
    rb_ary_push(result, prof_method_wrap(call_tree->method));

    rb_st_foreach(call_tree->children, prof_call_tree_collect_methods, result);

    return result;
}

void prof_call_tree_add_parent(prof_call_tree_t* self, prof_call_tree_t* parent)
{
    prof_call_tree_add_child(parent, self);
    self->parent = parent;
}

void prof_call_tree_add_child(prof_call_tree_t* self, prof_call_tree_t* child)
{
    call_tree_table_insert(self->children, child->method->key, child);
    
    // The child is now managed by C since its parent will free it
    child->owner = OWNER_C;
}

/* =======  RubyProf::CallTree   ========*/

/* call-seq:
   new(method_info) -> call_tree

Creates a new CallTree instance. +Klass+ should be a reference to
a Ruby class and +method_name+ a symbol identifying one of its instance methods.*/
static VALUE prof_call_tree_initialize(VALUE self, VALUE method_info)
{
  prof_call_tree_t* call_tree_ptr = prof_get_call_tree(self);
  call_tree_ptr->method = prof_get_method(method_info);

  return self;
}

/* call-seq:
   parent -> call_tree

Returns the CallTree parent call_tree object (the method that called this method).*/
static VALUE prof_call_tree_parent(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    if (call_tree->parent)
        return prof_call_tree_wrap(call_tree->parent);
    else
        return Qnil;
}

/* call-seq:
   callees -> array

Returns an array of call info objects that this method called (ie, children).*/
static VALUE prof_call_tree_children(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    VALUE result = rb_ary_new();
    rb_st_foreach(call_tree->children, prof_call_tree_collect_children, result);
    return result;
}

/* call-seq:
   add_child(call_tree) -> call_tree

Adds the specified call_tree as a child. If the method represented by the call tree is
already a child than a IndexError is thrown.

The returned value is the added child*/
static VALUE prof_call_tree_add_child_ruby(VALUE self, VALUE child)
{
  prof_call_tree_t* parent_ptr = prof_get_call_tree(self);
  prof_call_tree_t* child_ptr = prof_get_call_tree(child);

  prof_call_tree_t* existing_ptr = call_tree_table_lookup(parent_ptr->children, child_ptr->method->key);
  if (existing_ptr)
  {
    rb_raise(rb_eIndexError, "Child call tree already exists");
  }

  prof_call_tree_add_parent(child_ptr, parent_ptr);

  return child;
}

/* call-seq:
   called -> MethodInfo

Returns the target method. */
static VALUE prof_call_tree_target(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    return prof_method_wrap(call_tree->method);
}

/* call-seq:
   called -> Measurement

Returns the measurement associated with this call_tree. */
static VALUE prof_call_tree_measurement(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    return prof_measurement_wrap(call_tree->measurement);
}

/* call-seq:
   depth -> int

   returns the depth of this call info in the call graph */
static VALUE prof_call_tree_depth(VALUE self)
{
    prof_call_tree_t* call_tree_data = prof_get_call_tree(self);
    uint32_t depth = prof_call_tree_figure_depth(call_tree_data);
    return rb_int_new(depth);
}

/* call-seq:
   source_file => string

return the source file of the method
*/
static VALUE prof_call_tree_source_file(VALUE self)
{
    prof_call_tree_t* result = prof_get_call_tree(self);
    return result->source_file;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE prof_call_tree_line(VALUE self)
{
    prof_call_tree_t* result = prof_get_call_tree(self);
    return INT2FIX(result->source_line);
}

// Helper class that lets us pass additional information to prof_call_tree_merge_children
typedef struct self_info_t
{
  prof_call_tree_t* call_tree;
  st_table* method_table;
} self_info_t;


static int prof_call_tree_merge_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_tree_t* other_child_ptr = (prof_call_tree_t*)value;

    self_info_t* self_info = (self_info_t*)data;
    prof_call_tree_t* self_ptr = self_info->call_tree;

    prof_call_tree_t* self_child = call_tree_table_lookup(self_ptr->children, other_child_ptr->method->key);
    if (self_child)
    {
        // Merge measurements
        prof_measurement_merge_internal(self_child->measurement, other_child_ptr->measurement);
    }
    else
    {
        // Get pointer to method the other call tree invoked
        prof_method_t* method_ptr = method_table_lookup(self_info->method_table, other_child_ptr->method->key);
      
        // Now copy the other call tree, reset its method pointer, and add it as a child
        self_child = prof_call_tree_copy(other_child_ptr);
        self_child->method = method_ptr;
        prof_call_tree_add_child(self_ptr, self_child);

        // Now tell the method that this call tree invoked it
        prof_add_call_tree(method_ptr->call_trees, self_child);
    }

    // Recurse down a level to merge children
    self_info_t child_info = { .call_tree = self_child, .method_table = self_info->method_table };
    rb_st_foreach(other_child_ptr->children, prof_call_tree_merge_children, (st_data_t)&child_info);

    return ST_CONTINUE;
}

void prof_call_tree_merge_internal(prof_call_tree_t* self, prof_call_tree_t* other, st_table* self_method_table)
{
    // Make sure the methods are the same
    if (self->method->key != other->method->key)
        return;

    // Make sure the parents are the same.
    // 1. They can both be set and be equal
    // 2. They can both be unset (null)
    if (self->parent && other->parent)
    {
        if (self->parent->method->key != other->parent->method->key)
            return;
    }
    else if (self->parent || other->parent)
    {
        return;
    }

    // Merge measurements
    prof_measurement_merge_internal(self->measurement, other->measurement);

    // Now recursively descend through the call trees
    self_info_t self_info = { .call_tree = self, .method_table = self_method_table };
    rb_st_foreach(other->children, prof_call_tree_merge_children, (st_data_t)&self_info);
}

/* :nodoc: */
static VALUE prof_call_tree_dump(VALUE self)
{
    prof_call_tree_t* call_tree_data = prof_get_call_tree(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("owner")), INT2FIX(call_tree_data->owner));

    rb_hash_aset(result, ID2SYM(rb_intern("measurement")), prof_measurement_wrap(call_tree_data->measurement));

    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), call_tree_data->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(call_tree_data->source_line));

    rb_hash_aset(result, ID2SYM(rb_intern("parent")), prof_call_tree_parent(self));
    rb_hash_aset(result, ID2SYM(rb_intern("children")), prof_call_tree_children(self));
    rb_hash_aset(result, ID2SYM(rb_intern("target")), prof_call_tree_target(self));

    return result;
}

/* :nodoc: */
static VALUE prof_call_tree_load(VALUE self, VALUE data)
{
    VALUE target = Qnil;
    VALUE parent = Qnil;
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    call_tree->object = self;

    call_tree->owner = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("owner"))));

    VALUE measurement = rb_hash_aref(data, ID2SYM(rb_intern("measurement")));
    call_tree->measurement = prof_get_measurement(measurement);

    call_tree->source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    call_tree->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));

    parent = rb_hash_aref(data, ID2SYM(rb_intern("parent")));
    if (parent != Qnil)
        call_tree->parent = prof_get_call_tree(parent);

    VALUE callees = rb_hash_aref(data, ID2SYM(rb_intern("children")));
    for (int i = 0; i < rb_array_len(callees); i++)
    {
        VALUE call_tree_object = rb_ary_entry(callees, i);
        prof_call_tree_t* call_tree_data = prof_get_call_tree(call_tree_object);

        st_data_t key = call_tree_data->method ? call_tree_data->method->key : method_key(Qnil, 0);
        call_tree_table_insert(call_tree->children, key, call_tree_data);
    }

    target = rb_hash_aref(data, ID2SYM(rb_intern("target")));
    call_tree->method = prof_get_method(target);

    return data;
}

void rp_init_call_tree(void)
{
    /* CallTree */
    cRpCallTree = rb_define_class_under(mProf, "CallTree", rb_cObject);
    rb_define_alloc_func(cRpCallTree, prof_call_tree_allocate);
    rb_define_method(cRpCallTree, "initialize", prof_call_tree_initialize, 1);

    rb_define_method(cRpCallTree, "target", prof_call_tree_target, 0);
    rb_define_method(cRpCallTree, "measurement", prof_call_tree_measurement, 0);
    rb_define_method(cRpCallTree, "parent", prof_call_tree_parent, 0);
    rb_define_method(cRpCallTree, "children", prof_call_tree_children, 0);
    rb_define_method(cRpCallTree, "add_child", prof_call_tree_add_child_ruby, 1);

    rb_define_method(cRpCallTree, "depth", prof_call_tree_depth, 0);
    rb_define_method(cRpCallTree, "source_file", prof_call_tree_source_file, 0);
    rb_define_method(cRpCallTree, "line", prof_call_tree_line, 0);

    rb_define_method(cRpCallTree, "_dump_data", prof_call_tree_dump, 0);
    rb_define_method(cRpCallTree, "_load_data", prof_call_tree_load, 1);
}
