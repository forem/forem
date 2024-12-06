/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_trees.h"
#include "rp_measurement.h"

#define INITIAL_CALL_TREES_SIZE 2

VALUE cRpCallTrees;

/* =======  Call Infos   ========*/
prof_call_trees_t* prof_get_call_trees(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_call_trees_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::CallTrees instance has already been freed, likely because its profile has been freed.");

    return result;
}

prof_call_trees_t* prof_call_trees_create(void)
{
    prof_call_trees_t* result = ALLOC(prof_call_trees_t);
    result->start = ALLOC_N(prof_call_tree_t*, INITIAL_CALL_TREES_SIZE);
    result->end = result->start + INITIAL_CALL_TREES_SIZE;
    result->ptr = result->start;
    result->object = Qnil;
    return result;
}

void prof_call_trees_mark(void* data)
{
    if (!data) return;

    prof_call_trees_t* call_trees = (prof_call_trees_t*)data;
    prof_call_tree_t** call_tree;
    for (call_tree = call_trees->start; call_tree < call_trees->ptr; call_tree++)
    {
        prof_call_tree_mark(*call_tree);
    }
}

void prof_call_trees_free(prof_call_trees_t* call_trees)
{
    /* Has this method object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (call_trees->object != Qnil)
    {
        RTYPEDDATA(call_trees->object)->data = NULL;
        call_trees->object = Qnil;
    }

    // Note we do not free our call_tree structures - since they have no parents they will free themselves
    xfree(call_trees);
}

void prof_call_trees_ruby_gc_free(void* data)
{
    if (data)
    {
        // This object gets freed by its owning method
        prof_call_trees_t* call_trees = (prof_call_trees_t*)data;
        call_trees->object = Qnil;
    }
}

static int prof_call_trees_collect(st_data_t key, st_data_t value, st_data_t data)
{
    VALUE result = (VALUE)data;
    prof_call_tree_t* call_tree_data = (prof_call_tree_t*)value;
    VALUE aggregate_call_tree = prof_call_tree_wrap(call_tree_data);
    rb_ary_push(result, aggregate_call_tree);

    return ST_CONTINUE;
}

static int prof_call_trees_collect_callees(st_data_t key, st_data_t value, st_data_t hash)
{
    st_table* callers = (st_table*)hash;
    prof_call_tree_t* call_tree_data = (prof_call_tree_t*)value;

    prof_call_tree_t* aggregate_call_tree_data = NULL;

    if (rb_st_lookup(callers, call_tree_data->method->key, (st_data_t*)&aggregate_call_tree_data))
    {
      prof_measurement_merge_internal(aggregate_call_tree_data->measurement, call_tree_data->measurement);
    }
    else
    {
        // Copy the call tree so we don't touch the original and give Ruby ownerhip 
        // of it so that it is freed on GC
        aggregate_call_tree_data = prof_call_tree_copy(call_tree_data);
        aggregate_call_tree_data->owner = OWNER_RUBY;


        rb_st_insert(callers, call_tree_data->method->key, (st_data_t)aggregate_call_tree_data);
    }

    return ST_CONTINUE;
}

size_t prof_call_trees_size(const void* data)
{
    return sizeof(prof_call_trees_t);
}

static const rb_data_type_t call_trees_type =
{
    .wrap_struct_name = "CallTrees",
    .function =
    {
        .dmark = prof_call_trees_mark,
        .dfree = prof_call_trees_ruby_gc_free,
        .dsize = prof_call_trees_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_call_trees_wrap(prof_call_trees_t* call_trees)
{
    if (call_trees->object == Qnil)
    {
        call_trees->object = TypedData_Wrap_Struct(cRpCallTrees, &call_trees_type, call_trees);
    }
    return call_trees->object;
}

void prof_add_call_tree(prof_call_trees_t* call_trees, prof_call_tree_t* call_tree)
{
    if (call_trees->ptr == call_trees->end)
    {
        size_t len = call_trees->ptr - call_trees->start;
        size_t new_capacity = (call_trees->end - call_trees->start) * 2;
        REALLOC_N(call_trees->start, prof_call_tree_t*, new_capacity);
        call_trees->ptr = call_trees->start + len;
        call_trees->end = call_trees->start + new_capacity;
    }
    *call_trees->ptr = call_tree;
    call_trees->ptr++;
}

/* ================  Call Infos   =================*/
/* Document-class: RubyProf::CallTrees
The RubyProf::MethodInfo class stores profiling data for a method.
One instance of the RubyProf::MethodInfo class is created per method
called per thread.  Thus, if a method is called in two different
thread then there will be two RubyProf::MethodInfo objects
created.  RubyProf::MethodInfo objects can be accessed via
the RubyProf::Profile object. */
VALUE prof_call_trees_allocate(VALUE klass)
{
    prof_call_trees_t* call_trees_data = prof_call_trees_create();
    call_trees_data->object = prof_call_trees_wrap(call_trees_data);
    return call_trees_data->object;
}


/* call-seq:
   min_depth -> Integer

Returns the minimum depth of this method in any call tree */
VALUE prof_call_trees_min_depth(VALUE self)
{
    unsigned int depth = INT_MAX;

    prof_call_trees_t* call_trees = prof_get_call_trees(self);
    for (prof_call_tree_t** p_call_tree = call_trees->start; p_call_tree < call_trees->ptr; p_call_tree++)
    {
        unsigned int call_tree_depth = prof_call_tree_figure_depth(*p_call_tree);
        if (call_tree_depth < depth)
            depth = call_tree_depth;
    }

    return UINT2NUM(depth);
}

/* call-seq:
   callers -> array

Returns an array of all CallTree objects that called this method. */
VALUE prof_call_trees_call_trees(VALUE self)
{
    VALUE result = rb_ary_new();

    prof_call_trees_t* call_trees = prof_get_call_trees(self);
    for (prof_call_tree_t** p_call_tree = call_trees->start; p_call_tree < call_trees->ptr; p_call_tree++)
    {
        VALUE call_tree = prof_call_tree_wrap(*p_call_tree);
        rb_ary_push(result, call_tree);
    }
    return result;
}

/* call-seq:
   callers -> array

Returns an array of aggregated CallTree objects that called this method (ie, parents).*/
VALUE prof_call_trees_callers(VALUE self)
{
    st_table* callers = rb_st_init_numtable();

    prof_call_trees_t* call_trees = prof_get_call_trees(self);
    for (prof_call_tree_t** p_call_tree = call_trees->start; p_call_tree < call_trees->ptr; p_call_tree++)
    {
        prof_call_tree_t* parent = (*p_call_tree)->parent;
        if (parent == NULL)
            continue;

        prof_call_tree_t* aggregate_call_tree_data = NULL;

        if (rb_st_lookup(callers, parent->method->key, (st_data_t*)&aggregate_call_tree_data))
        {
          prof_measurement_merge_internal(aggregate_call_tree_data->measurement, (*p_call_tree)->measurement);
        }
        else
        {
            // Copy the call tree so we don't touch the original and give Ruby ownerhip 
            // of it so that it is freed on GC
            aggregate_call_tree_data = prof_call_tree_copy(*p_call_tree);
            aggregate_call_tree_data->owner = OWNER_RUBY;

            rb_st_insert(callers, parent->method->key, (st_data_t)aggregate_call_tree_data);
        }
    }

    VALUE result = rb_ary_new_capa((long)callers->num_entries);
    rb_st_foreach(callers, prof_call_trees_collect, result);
    rb_st_free_table(callers);
    return result;
}

/* call-seq:
   callees -> array

Returns an array of aggregated CallTree objects that this method called (ie, children).*/
VALUE prof_call_trees_callees(VALUE self)
{
    st_table* callees = rb_st_init_numtable();

    prof_call_trees_t* call_trees = prof_get_call_trees(self);
    for (prof_call_tree_t** call_tree = call_trees->start; call_tree < call_trees->ptr; call_tree++)
    {
        rb_st_foreach((*call_tree)->children, prof_call_trees_collect_callees, (st_data_t)callees);
    }

    VALUE result = rb_ary_new_capa((long)callees->num_entries);
    rb_st_foreach(callees, prof_call_trees_collect, result);
    rb_st_free_table(callees);
    return result;
}

/* :nodoc: */
VALUE prof_call_trees_dump(VALUE self)
{
    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("call_trees")), prof_call_trees_call_trees(self));

    return result;
}

/* :nodoc: */
VALUE prof_call_trees_load(VALUE self, VALUE data)
{
    prof_call_trees_t* call_trees_data = prof_get_call_trees(self);
    call_trees_data->object = self;

    VALUE call_trees = rb_hash_aref(data, ID2SYM(rb_intern("call_trees")));
    for (int i = 0; i < rb_array_len(call_trees); i++)
    {
        VALUE call_tree = rb_ary_entry(call_trees, i);
        prof_call_tree_t* call_tree_data = prof_get_call_tree(call_tree);
        prof_add_call_tree(call_trees_data, call_tree_data);
    }

    return data;
}

void rp_init_call_trees(void)
{
    cRpCallTrees = rb_define_class_under(mProf, "CallTrees", rb_cObject);
    rb_undef_method(CLASS_OF(cRpCallTrees), "new");
    rb_define_alloc_func(cRpCallTrees, prof_call_trees_allocate);

    rb_define_method(cRpCallTrees, "min_depth", prof_call_trees_min_depth, 0);

    rb_define_method(cRpCallTrees, "call_trees", prof_call_trees_call_trees, 0);
    rb_define_method(cRpCallTrees, "callers", prof_call_trees_callers, 0);
    rb_define_method(cRpCallTrees, "callees", prof_call_trees_callees, 0);

    rb_define_method(cRpCallTrees, "_dump_data", prof_call_trees_dump, 0);
    rb_define_method(cRpCallTrees, "_load_data", prof_call_trees_load, 1);
}
