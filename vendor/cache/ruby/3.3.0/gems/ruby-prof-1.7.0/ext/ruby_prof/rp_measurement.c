/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_measurement.h"

VALUE mMeasure;
VALUE cRpMeasurement;

prof_measurer_t* prof_measurer_allocations(bool track_allocations);
prof_measurer_t* prof_measurer_memory(bool track_allocations);
prof_measurer_t* prof_measurer_process_time(bool track_allocations);
prof_measurer_t* prof_measurer_wall_time(bool track_allocations);

void rp_init_measure_allocations(void);
void rp_init_measure_memory(void);
void rp_init_measure_process_time(void);
void rp_init_measure_wall_time(void);

prof_measurer_t* prof_measurer_create(prof_measure_mode_t measure, bool track_allocations)
{
    switch (measure)
    {
    case MEASURE_WALL_TIME:
        return prof_measurer_wall_time(track_allocations);
    case MEASURE_PROCESS_TIME:
        return prof_measurer_process_time(track_allocations);
    case MEASURE_ALLOCATIONS:
        return prof_measurer_allocations(track_allocations);
    case MEASURE_MEMORY:
        return prof_measurer_memory(track_allocations);
    default:
        rb_raise(rb_eArgError, "Unknown measure mode: %d", measure);
    }
};

double prof_measure(prof_measurer_t* measurer, rb_trace_arg_t* trace_arg)
{
    double measurement = measurer->measure(trace_arg);
    return measurement * measurer->multiplier;
}

/* =======  prof_measurement_t   ========*/
prof_measurement_t* prof_measurement_create(void)
{
    prof_measurement_t* result = ALLOC(prof_measurement_t);
    result->owner = OWNER_C;
    result->total_time = 0;
    result->self_time = 0;
    result->wait_time = 0;
    result->called = 0;
    result->object = Qnil;
    return result;
}

/* call-seq:
     new(total_time, self_time, wait_time, called) -> Measurement

   Creates a new measuremen instance. */
static VALUE prof_measurement_initialize(VALUE self, VALUE total_time, VALUE self_time, VALUE wait_time, VALUE called)
{
  prof_measurement_t* result = prof_get_measurement(self);

  result->total_time = NUM2DBL(total_time);
  result->self_time = NUM2DBL(self_time);
  result->wait_time = NUM2DBL(wait_time);
  result->called = NUM2INT(called);
  result->object = self;
  return self;
}

prof_measurement_t* prof_measurement_copy(prof_measurement_t* other)
{
  prof_measurement_t* result = prof_measurement_create();
  result->called = other->called;
  result->total_time = other->total_time;
  result->self_time = other->self_time;
  result->wait_time = other->wait_time;

  return result;
}

static VALUE prof_measurement_initialize_copy(VALUE self, VALUE other)
{
  // This object was created by Ruby either via Measurment#clone or Measurement#dup 
  // and thus prof_measurement_allocate was called so the object is owned by Ruby

  if (self == other)
    return self;

  prof_measurement_t* self_ptr = prof_get_measurement(self);
  prof_measurement_t* other_ptr = prof_get_measurement(other);

  self_ptr->called = other_ptr->called;
  self_ptr->total_time = other_ptr->total_time;
  self_ptr->self_time = other_ptr->self_time;
  self_ptr->wait_time = other_ptr->wait_time;

  return self;
}

void prof_measurement_mark(void* data)
{
    if (!data) return;

    prof_measurement_t* measurement = (prof_measurement_t*)data;

    if (measurement->object != Qnil)
        rb_gc_mark_movable(measurement->object);
}

void prof_measurement_compact(void* data)
{
    prof_measurement_t* measurement = (prof_measurement_t*)data;
    measurement->object = rb_gc_location(measurement->object);
}

void prof_measurement_free(prof_measurement_t* measurement)
{
    /* Has this measurement object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (measurement->object != Qnil)
    {
        RTYPEDDATA(measurement->object)->data = NULL;
        measurement->object = Qnil;
    }

    xfree(measurement);
}

static void prof_measurement_ruby_gc_free(void* data)
{
  prof_measurement_t* measurement = (prof_measurement_t*)data;

  if (!measurement)
  {
    // Object has already been freed by C code
    return;
  }
  else if (measurement->owner == OWNER_RUBY)
  {
    // Ruby owns this object, we need to free the underlying C struct
    prof_measurement_free(measurement);
  }
  else
  {
    // The Ruby object is being freed, but not the underlying C structure. So unlink the two.
    measurement->object = Qnil;
  }
}

size_t prof_measurement_size(const void* data)
{
    return sizeof(prof_measurement_t);
}

static const rb_data_type_t measurement_type =
{
    .wrap_struct_name = "Measurement",
    .function =
    {
        .dmark = prof_measurement_mark,
        .dfree = prof_measurement_ruby_gc_free,
        .dsize = prof_measurement_size,
        .dcompact = prof_measurement_compact
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_measurement_wrap(prof_measurement_t* measurement)
{
    if (measurement->object == Qnil)
    {
        measurement->object = TypedData_Wrap_Struct(cRpMeasurement, &measurement_type, measurement);
    }
    return measurement->object;
}

static VALUE prof_measurement_allocate(VALUE klass)
{
    prof_measurement_t* measurement = prof_measurement_create();
    // This object is being created by Ruby
    measurement->owner = OWNER_RUBY;
    measurement->object = prof_measurement_wrap(measurement);
    return measurement->object;
}

prof_measurement_t* prof_get_measurement(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_measurement_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Measurement instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* call-seq:
   total_time -> float

Returns the total amount of time spent in this method and its children. */
static VALUE prof_measurement_total_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);
    return rb_float_new(result->total_time);
}

/* call-seq:
   total_time=value -> value

Sets the call count to n. */
static VALUE prof_measurement_set_total_time(VALUE self, VALUE value)
{
  prof_measurement_t* result = prof_get_measurement(self);
  result->total_time = NUM2DBL(value);
  return value;
}

/* call-seq:
   self_time -> float

Returns the total amount of time spent in this method. */
static VALUE
prof_measurement_self_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);

    return rb_float_new(result->self_time);
}

/* call-seq:
   self_time=value -> value

Sets the call count to value. */
static VALUE prof_measurement_set_self_time(VALUE self, VALUE value)
{
  prof_measurement_t* result = prof_get_measurement(self);
  result->self_time = NUM2DBL(value);
  return value;
}

/* call-seq:
   wait_time -> float

Returns the total amount of time this method waited for other threads. */
static VALUE prof_measurement_wait_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);

    return rb_float_new(result->wait_time);
}

/* call-seq:
   wait_time=value -> value

Sets the wait time to value. */
static VALUE prof_measurement_set_wait_time(VALUE self, VALUE value)
{
  prof_measurement_t* result = prof_get_measurement(self);
  result->wait_time = NUM2DBL(value);
  return value;
}

/* call-seq:
   called -> int

Returns the total amount of times this method was called. */
static VALUE prof_measurement_called(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);
    return INT2NUM(result->called);
}

/* call-seq:
   called=value -> value

Sets the call count to value. */
static VALUE prof_measurement_set_called(VALUE self, VALUE value)
{
  prof_measurement_t* result = prof_get_measurement(self);
  result->called = NUM2INT(value);
  return value;
}

/* :nodoc: */
void prof_measurement_merge_internal(prof_measurement_t* self, prof_measurement_t* other)
{
  self->called += other->called;
  self->total_time += other->total_time;
  self->self_time += other->self_time;
  self->wait_time += other->wait_time;
}

/* call-seq:
   merge(other)

   Adds the content of other measurement to this measurement */
VALUE prof_measurement_merge(VALUE self, VALUE other)
{
  prof_measurement_t* self_ptr = prof_get_measurement(self);
  prof_measurement_t* other_ptr = prof_get_measurement(other);
  prof_measurement_merge_internal(self_ptr, other_ptr);
  return self;
}

/* :nodoc: */
static VALUE prof_measurement_dump(VALUE self)
{
    prof_measurement_t* measurement_data = prof_get_measurement(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("owner")), INT2FIX(measurement_data->owner));
    rb_hash_aset(result, ID2SYM(rb_intern("total_time")), rb_float_new(measurement_data->total_time));
    rb_hash_aset(result, ID2SYM(rb_intern("self_time")), rb_float_new(measurement_data->self_time));
    rb_hash_aset(result, ID2SYM(rb_intern("wait_time")), rb_float_new(measurement_data->wait_time));
    rb_hash_aset(result, ID2SYM(rb_intern("called")), INT2FIX(measurement_data->called));

    return result;
}

/* :nodoc: */
static VALUE
prof_measurement_load(VALUE self, VALUE data)
{
    prof_measurement_t* measurement = prof_get_measurement(self);
    measurement->object = self;

    measurement->owner = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("owner"))));
    measurement->total_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("total_time"))));
    measurement->self_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("self_time"))));
    measurement->wait_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("wait_time"))));
    measurement->called = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("called"))));

    return data;
}

void rp_init_measure(void)
{
    mMeasure = rb_define_module_under(mProf, "Measure");
    rp_init_measure_wall_time();
    rp_init_measure_process_time();
    rp_init_measure_allocations();
    rp_init_measure_memory();

    cRpMeasurement = rb_define_class_under(mProf, "Measurement", rb_cObject);
    rb_define_alloc_func(cRpMeasurement, prof_measurement_allocate);

    rb_define_method(cRpMeasurement, "initialize", prof_measurement_initialize, 4);
    rb_define_method(cRpMeasurement, "initialize_copy", prof_measurement_initialize_copy, 1);
    rb_define_method(cRpMeasurement, "merge!", prof_measurement_merge, 1);
    rb_define_method(cRpMeasurement, "called", prof_measurement_called, 0);
    rb_define_method(cRpMeasurement, "called=", prof_measurement_set_called, 1);
    rb_define_method(cRpMeasurement, "total_time", prof_measurement_total_time, 0);
    rb_define_method(cRpMeasurement, "total_time=", prof_measurement_set_total_time, 1);
    rb_define_method(cRpMeasurement, "self_time", prof_measurement_self_time, 0);
    rb_define_method(cRpMeasurement, "self_time=", prof_measurement_set_self_time, 1);
    rb_define_method(cRpMeasurement, "wait_time", prof_measurement_wait_time, 0);
    rb_define_method(cRpMeasurement, "wait_time=", prof_measurement_set_wait_time, 1);

    rb_define_method(cRpMeasurement, "_dump_data", prof_measurement_dump, 0);
    rb_define_method(cRpMeasurement, "_load_data", prof_measurement_load, 1);
}
