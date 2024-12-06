#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Builtin_Object);

SETUP(Builtin_Object)
{
  embed_ruby();
}

TESTCASE(construct_with_object)
{
  Class c(rb_cObject);
  Object o(c.call("new"));
  Builtin_Object<T_OBJECT> b(o);
  ASSERT_EQUAL(o.value(), b.value());
  ASSERT_EQUAL(T_OBJECT, rb_type(b.value()));
  ASSERT_EQUAL(rb_cObject, b.class_of().value());
  ASSERT_EQUAL(rb_cObject, CLASS_OF(b.value()));
}

TESTCASE(copy_construct)
{
  Class c(rb_cObject);
  Object o(c.call("new"));
  Builtin_Object<T_OBJECT> b(o);
  Builtin_Object<T_OBJECT> b2(b);
  ASSERT_EQUAL(o.value(), b2.value());
  ASSERT_EQUAL(T_OBJECT, rb_type(b2.value()));
  ASSERT_EQUAL(rb_cObject, b2.class_of().value());
  ASSERT_EQUAL(rb_cObject, CLASS_OF(b2.value()));
}

TESTCASE(copy_assign)
{
  Class c(rb_cObject);
  Builtin_Object<T_OBJECT> b1(c.call("new"));
  Builtin_Object<T_OBJECT> b2(c.call("new"));
  
  b2 = b1;

  ASSERT_EQUAL(b2.value(), b1.value());
}

TESTCASE(move_constructor)
{
  Class c(rb_cObject);
  Builtin_Object<T_OBJECT> b1(c.call("new"));
  Builtin_Object<T_OBJECT> b2(std::move(b1));

  ASSERT_NOT_EQUAL(b2.value(), b1.value());
  ASSERT_EQUAL(b1.value(), Qnil);
}

TESTCASE(move_assign)
{
  Class c(rb_cObject);
  Builtin_Object<T_OBJECT> b1(c.call("new"));
  Builtin_Object<T_OBJECT> b2(c.call("new"));

  b2 = std::move(b1);

  ASSERT_NOT_EQUAL(b2.value(), b1.value());
  ASSERT_EQUAL(b1.value(), Qnil);
}

TESTCASE(dereference)
{
  Class c(rb_cObject);
  Object o(c.call("new"));
  Builtin_Object<T_OBJECT> b(o);
  ASSERT_EQUAL(ROBJECT(o.value()), &*b);
}

TESTCASE(arrow)
{
  Class c(rb_cObject);
  Object o(c.call("new"));
  Builtin_Object<T_OBJECT> b(o);
  ASSERT_EQUAL(rb_cObject, b->basic.klass);
}

TESTCASE(get)
{
  Class c(rb_cObject);
  Object o(c.call("new"));
  Builtin_Object<T_OBJECT> b(o);
  ASSERT_EQUAL(ROBJECT(o.value()), b.get());
}
