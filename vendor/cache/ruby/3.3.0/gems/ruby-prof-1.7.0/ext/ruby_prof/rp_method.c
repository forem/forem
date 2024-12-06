/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_allocation.h"
#include "rp_call_trees.h"
#include "rp_method.h"
#include "rp_profile.h"

#include <ruby/version.h>

// Needed for Ruby 3.0.* and 3.1.*
#if RUBY_API_VERSION_MAJOR == 3 && RUBY_API_VERSION_MINOR < 2
   VALUE rb_class_attached_object(VALUE klass)
   {
     return rb_iv_get(klass, "__attached__");
   }
#endif

VALUE cRpMethodInfo;

/* ================  Helper Functions  =================*/
VALUE resolve_klass(VALUE klass, unsigned int* klass_flags)
{
    VALUE result = klass;

    if (klass == 0 || klass == Qnil)
    {
        result = Qnil;
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON))
    {
        /* We have come across a singleton object. First
           figure out what it is attached to.*/
        VALUE attached = rb_class_attached_object(klass);

        switch (BUILTIN_TYPE(attached))
        {
            /* Is this a singleton class acting as a metaclass? */
            case T_CLASS:
            {
                *klass_flags |= kClassSingleton;
                result = attached;
                break;
            }
            /* Is this for singleton methods on a module? */
            case T_MODULE:
            {
                *klass_flags |= kModuleSingleton;
                result = attached;
                break;
            }
            /* Is this for singleton methods on an object? */
            case T_OBJECT:
            {
                *klass_flags |= kObjectSingleton;
                result = rb_class_superclass(klass);
                break;
            }
            /* Ok, this could be other things like an array put onto
               a singleton object (yeah, it happens, see the singleton
               objects test case). */
            default:
            {
                *klass_flags |= kOtherSingleton;
                result = klass;
                break;
            }
        }
    }
    /* Is this an include for a module?  If so get the actual
        module class since we want to combine all profiling
        results for that module. */
    else if (BUILTIN_TYPE(klass) == T_ICLASS)
    {
        unsigned int dummy;
        *klass_flags |= kModuleIncludee;
        result = resolve_klass(RBASIC_CLASS(klass), &dummy);
    }
    return result;
}

VALUE resolve_klass_name(VALUE klass, unsigned int* klass_flags)
{
    VALUE result = Qnil;

    if (klass == Qnil)
    {
        result = rb_str_new2("[global]");
    }
    else if (*klass_flags & kOtherSingleton)
    {
        result = rb_any_to_s(klass);
    }
    else
    {
        result = rb_class_name(klass);
    }

    return result;
}

st_data_t method_key(VALUE klass, VALUE msym)
{
    VALUE resolved_klass = klass;

    /* Is this an include for a module?  If so get the actual
        module class since we want to combine all profiling
        results for that module. */
    if (klass == 0 || klass == Qnil)
    {
        resolved_klass = Qnil;
    }
    else if (BUILTIN_TYPE(klass) == T_ICLASS)
    {
        resolved_klass = RBASIC_CLASS(klass);
    }

    st_data_t hash = rb_hash_start(0);
    hash = rb_hash_uint(hash, resolved_klass);
    hash = rb_hash_uint(hash, msym);
    hash = rb_hash_end(hash);

    return hash;
}

/* ================  prof_method_t   =================*/
prof_method_t* prof_get_method(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_method_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::MethodInfo instance has already been freed, likely because its profile has been freed.");

    return result;
}

prof_method_t* prof_method_create(struct prof_profile_t* profile, VALUE klass, VALUE msym, VALUE source_file, int source_line)
{
    prof_method_t* result = ALLOC(prof_method_t);
    result->profile = profile;

    result->key = method_key(klass, msym);
    result->klass_flags = 0;

    /* Note we do not call resolve_klass_name now because that causes an object allocation that shows up
       in the allocation results so we want to avoid it until after the profile run is complete. */
    result->klass = resolve_klass(klass, &result->klass_flags);
    result->klass_name = Qnil;
    result->method_name = msym;
    result->measurement = prof_measurement_create();

    result->call_trees = prof_call_trees_create();
    result->allocations_table = prof_allocations_create();

    result->visits = 0;
    result->recursive = false;

    result->object = Qnil;

    result->source_file = source_file;
    result->source_line = source_line;

    return result;
}

prof_method_t* prof_method_copy(prof_method_t* other)
{
    prof_method_t* result = prof_method_create(other->profile, other->klass, other->method_name, other->source_file, other->source_line);
    result->measurement = prof_measurement_copy(other->measurement);

    return result;
}

/* The underlying c structures are freed when the parent profile is freed.
   However, on shutdown the Ruby GC frees objects in any will-nilly order.
   That means the ruby thread object wrapping the c thread struct may
   be freed before the parent profile.  Thus we add in a free function
   for the garbage collector so that if it does get called will nil
   out our Ruby object reference.*/
static void prof_method_ruby_gc_free(void* data)
{
    if (data)
    {
        prof_method_t* method = (prof_method_t*)data;
        method->object = Qnil;
    }
}

static void prof_method_free(prof_method_t* method)
{
    /* Has this method object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (method->object != Qnil)
    {
        RTYPEDDATA(method->object)->data = NULL;
        method->object = Qnil;
    }

    prof_allocations_free(method->allocations_table);
    prof_call_trees_free(method->call_trees);
    prof_measurement_free(method->measurement);
    xfree(method);
}

size_t prof_method_size(const void* data)
{
    return sizeof(prof_method_t);
}

void prof_method_mark(void* data)
{
    if (!data) return;

    prof_method_t* method = (prof_method_t*)data;

    if (method->object != Qnil)
      rb_gc_mark_movable(method->object);

    // Mark the profile to keep it alive. Can't call prof_profile_mark because that would
    // cause recursion
    if (method->profile && method->profile->object != Qnil)
        rb_gc_mark(method->profile->object);

    rb_gc_mark(method->klass_name);
    rb_gc_mark(method->method_name);
    rb_gc_mark(method->source_file);

    if (method->klass != Qnil)
        rb_gc_mark(method->klass);

    prof_measurement_mark(method->measurement);
    prof_allocations_mark(method->allocations_table);
}

void prof_method_compact(void* data)
{
    prof_method_t* method = (prof_method_t*)data;
    method->object = rb_gc_location(method->object);
    method->klass_name = rb_gc_location(method->klass_name);
    method->method_name = rb_gc_location(method->method_name);
}

static VALUE prof_method_allocate(VALUE klass)
{
    prof_method_t* method_data = prof_method_create(NULL, Qnil, Qnil, Qnil, 0);
    method_data->object = prof_method_wrap(method_data);
    return method_data->object;
}

static const rb_data_type_t method_info_type =
{
    .wrap_struct_name = "MethodInfo",
    .function =
    {
        .dmark = prof_method_mark,
        .dfree = prof_method_ruby_gc_free,
        .dsize = prof_method_size,
        .dcompact = prof_method_compact
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_method_wrap(prof_method_t* method)
{
    if (method->object == Qnil)
    {
        method->object = TypedData_Wrap_Struct(cRpMethodInfo, &method_info_type, method);
    }
    return method->object;
}

st_table* method_table_create(void)
{
    return rb_st_init_numtable();
}

static int method_table_free_iterator(st_data_t key, st_data_t value, st_data_t dummy)
{
    prof_method_free((prof_method_t*)value);
    return ST_CONTINUE;
}

void method_table_free(st_table* table)
{
    rb_st_foreach(table, method_table_free_iterator, 0);
    rb_st_free_table(table);
}

size_t method_table_insert(st_table* table, st_data_t key, prof_method_t* val)
{
    return rb_st_insert(table, (st_data_t)key, (st_data_t)val);
}

static int prof_method_table_merge_internal(st_data_t key, st_data_t value, st_data_t data)
{
    st_table* self_table = (st_table*)data;
    prof_method_t* other_child = (prof_method_t*)value;

    prof_method_t* self_child = method_table_lookup(self_table, other_child->key);
    if (self_child)
    {
        prof_measurement_merge_internal(self_child->measurement, other_child->measurement);
    }
    else
    {
        prof_method_t* copy = prof_method_copy(other_child);
        method_table_insert(self_table, copy->key, copy); 
    }
  
    return ST_CONTINUE;
}

void prof_method_table_merge(st_table* self, st_table* other)
{   
  rb_st_foreach(other, prof_method_table_merge_internal, (st_data_t)self);
}

prof_method_t* method_table_lookup(st_table* table, st_data_t key)
{
    st_data_t val;
    if (rb_st_lookup(table, (st_data_t)key, &val))
    {
        return (prof_method_t*)val;
    }
    else
    {
        return NULL;
    }
}

/* ================  Method Info   =================*/
/* Document-class: RubyProf::MethodInfo
The RubyProf::MethodInfo class stores profiling data for a method.
One instance of the RubyProf::MethodInfo class is created per method
called per thread.  Thus, if a method is called in two different
thread then there will be two RubyProf::MethodInfo objects
created.  RubyProf::MethodInfo objects can be accessed via
the RubyProf::Profile object.
*/

/* call-seq:
   new(klass, method_name) -> method_info

Creates a new MethodInfo instance. +Klass+ should be a reference to
a Ruby class and +method_name+ a symbol identifying one of its instance methods.*/
static VALUE prof_method_initialize(VALUE self, VALUE klass, VALUE method_name)
{
  prof_method_t* method_ptr = prof_get_method(self);
  method_ptr->klass = klass;
  method_ptr->method_name = method_name;

  // Setup method key
  method_ptr->key = method_key(klass, method_name);

  // Get method object
  VALUE ruby_method = rb_funcall(klass, rb_intern("instance_method"), 1, method_name);

  // Get source file and line number
  VALUE location_array = rb_funcall(ruby_method, rb_intern("source_location"), 0);
  if (location_array != Qnil && RARRAY_LEN(location_array) == 2)
  {
    method_ptr->source_file = rb_ary_entry(location_array, 0);
    method_ptr->source_line = NUM2INT(rb_ary_entry(location_array, 1));
  }

  return self;
}

/* call-seq:
   hash -> hash

Returns the hash key for this method info. The hash key is calculated based on the
klass name and method name */
static VALUE prof_method_hash(VALUE self)
{
  prof_method_t* method_ptr = prof_get_method(self);
  return ULL2NUM(method_ptr->key);
}

/* call-seq:
   allocations -> array

Returns an array of allocation information.*/
static VALUE prof_method_allocations(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return prof_allocations_wrap(method->allocations_table);
}

/* call-seq:
   called -> Measurement

Returns the measurement associated with this method. */
static VALUE prof_method_measurement(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return prof_measurement_wrap(method->measurement);
}

/* call-seq:
   source_file => string

Returns the source file of the method
*/
static VALUE prof_method_source_file(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return method->source_file;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE prof_method_line(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return INT2FIX(method->source_line);
}

/* call-seq:
   klass_name -> String

Returns the name of this method's class.  Singleton classes
will have the form <Object::Object>. */

static VALUE prof_method_klass_name(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    if (method->klass_name == Qnil)
        method->klass_name = resolve_klass_name(method->klass, &method->klass_flags);

    return method->klass_name;
}

/* call-seq:
   klass_flags -> integer

Returns the klass flags */

static VALUE prof_method_klass_flags(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return INT2FIX(method->klass_flags);
}

/* call-seq:
   method_name -> Symbol

Returns the name of this method in the format Object#method. Singletons
methods will be returned in the format <Object::Object>#method.*/

static VALUE prof_method_name(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return method->method_name;
}

/* call-seq:
   recursive? -> boolean

   Returns the true if this method is recursively invoked */
static VALUE prof_method_recursive(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return method->recursive ? Qtrue : Qfalse;
}

/* call-seq:
   call_trees -> CallTrees

Returns the CallTrees associated with this method. */
static VALUE prof_method_call_trees(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    return prof_call_trees_wrap(method->call_trees);
}

/* :nodoc: */
static VALUE prof_method_dump(VALUE self)
{
    prof_method_t* method_data = prof_get_method(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("klass_name")), prof_method_klass_name(self));
    rb_hash_aset(result, ID2SYM(rb_intern("klass_flags")), INT2FIX(method_data->klass_flags));
    rb_hash_aset(result, ID2SYM(rb_intern("method_name")), method_data->method_name);

    rb_hash_aset(result, ID2SYM(rb_intern("key")), ULL2NUM(method_data->key));
    rb_hash_aset(result, ID2SYM(rb_intern("recursive")), prof_method_recursive(self));
    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), method_data->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(method_data->source_line));

    rb_hash_aset(result, ID2SYM(rb_intern("call_trees")), prof_call_trees_wrap(method_data->call_trees));
    rb_hash_aset(result, ID2SYM(rb_intern("measurement")), prof_measurement_wrap(method_data->measurement));
    rb_hash_aset(result, ID2SYM(rb_intern("allocations")), prof_method_allocations(self));

    return result;
}

/* :nodoc: */
static VALUE prof_method_load(VALUE self, VALUE data)
{
    prof_method_t* method_data = prof_get_method(self);
    method_data->object = self;

    method_data->klass_name = rb_hash_aref(data, ID2SYM(rb_intern("klass_name")));
    method_data->klass_flags = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("klass_flags"))));
    method_data->method_name = rb_hash_aref(data, ID2SYM(rb_intern("method_name")));
    method_data->key = RB_NUM2ULL(rb_hash_aref(data, ID2SYM(rb_intern("key"))));

    method_data->recursive = rb_hash_aref(data, ID2SYM(rb_intern("recursive"))) == Qtrue ? true : false;

    method_data->source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    method_data->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));

    VALUE call_trees = rb_hash_aref(data, ID2SYM(rb_intern("call_trees")));
    method_data->call_trees = prof_get_call_trees(call_trees);

    VALUE measurement = rb_hash_aref(data, ID2SYM(rb_intern("measurement")));
    method_data->measurement = prof_get_measurement(measurement);

    VALUE allocations = rb_hash_aref(data, ID2SYM(rb_intern("allocations")));
    prof_allocations_unwrap(method_data->allocations_table, allocations);
    return data;
}

void rp_init_method_info(void)
{
    /* MethodInfo */
    cRpMethodInfo = rb_define_class_under(mProf, "MethodInfo", rb_cObject);

    rb_define_const(cRpMethodInfo, "MODULE_INCLUDEE", INT2NUM(kModuleIncludee));
    rb_define_const(cRpMethodInfo, "CLASS_SINGLETON", INT2NUM(kClassSingleton));
    rb_define_const(cRpMethodInfo, "MODULE_SINGLETON", INT2NUM(kModuleSingleton));
    rb_define_const(cRpMethodInfo, "OBJECT_SINGLETON", INT2NUM(kObjectSingleton));
    rb_define_const(cRpMethodInfo, "OTHER_SINGLETON", INT2NUM(kOtherSingleton));

    rb_define_alloc_func(cRpMethodInfo, prof_method_allocate);
    rb_define_method(cRpMethodInfo, "initialize", prof_method_initialize, 2);
    rb_define_method(cRpMethodInfo, "hash", prof_method_hash, 0);

    rb_define_method(cRpMethodInfo, "klass_name", prof_method_klass_name, 0);
    rb_define_method(cRpMethodInfo, "klass_flags", prof_method_klass_flags, 0);
    rb_define_method(cRpMethodInfo, "method_name", prof_method_name, 0);

    rb_define_method(cRpMethodInfo, "call_trees", prof_method_call_trees, 0);

    rb_define_method(cRpMethodInfo, "allocations", prof_method_allocations, 0);
    rb_define_method(cRpMethodInfo, "measurement", prof_method_measurement, 0);

    rb_define_method(cRpMethodInfo, "source_file", prof_method_source_file, 0);
    rb_define_method(cRpMethodInfo, "line", prof_method_line, 0);

    rb_define_method(cRpMethodInfo, "recursive?", prof_method_recursive, 0);

    rb_define_method(cRpMethodInfo, "_dump_data", prof_method_dump, 0);
    rb_define_method(cRpMethodInfo, "_load_data", prof_method_load, 1);
}
