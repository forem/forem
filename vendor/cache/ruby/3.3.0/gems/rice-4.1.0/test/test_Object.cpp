#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Object);

SETUP(Object)
{
  embed_ruby();
}

TESTCASE(default_construct)
{
  Object o;
  ASSERT_EQUAL(Qnil, o.value());
}

TESTCASE(construct_with_value)
{
  Object o(INT2NUM(42));
  ASSERT_EQUAL(INT2NUM(42), o.value());
}

TESTCASE(copy_construct)
{
  Object o1(INT2NUM(42));
  Object o2(o1);
  ASSERT_EQUAL(o2.value(), o1.value());
}

TESTCASE(copy_assign)
{
  Object o1(INT2NUM(42));
  Object o2(INT2NUM(43));
  o2 = o1;
  ASSERT_EQUAL(o2.value(), o1.value());
}

TESTCASE(move_construct)
{
  Object o1(INT2NUM(42));
  Object o2(std::move(o1));
  ASSERT_EQUAL(o2.value(), INT2NUM(42));
  ASSERT_EQUAL(o1.value(), Qnil);
}

TESTCASE(move_assign)
{
  Object o1(INT2NUM(42));
  Object o2(INT2NUM(43));
  o2 = std::move(o1);
  ASSERT_EQUAL(o2.value(), INT2NUM(42));
  ASSERT_EQUAL(o1.value(), Qnil);
}

TESTCASE(test)
{
  ASSERT_EQUAL(true, Object(Qtrue).test());
  ASSERT_EQUAL(true, Object(INT2NUM(42)).test());
  ASSERT_EQUAL(false, Object(Qfalse).test());
  ASSERT_EQUAL(false, Object(Qnil).test());
  ASSERT_EQUAL(true, Object(Qundef).test());
}

TESTCASE(explicit_conversion_to_bool)
{
  // g++ 3.3.3 can't handle constructor-style inside the assert, which
  // is why we use cast-style here.
  ASSERT_EQUAL(true, (bool)Object(Qtrue));
  ASSERT_EQUAL(true, (bool)Object(INT2NUM(42)));
  ASSERT_EQUAL(false, (bool)Object(Qfalse));
  ASSERT_EQUAL(false, (bool)Object(Qnil));
  ASSERT_EQUAL(true, (bool)Object(Qundef));
}

TESTCASE(is_nil)
{
  ASSERT_EQUAL(false, Object(Qtrue).is_nil());
  ASSERT_EQUAL(false, Object(INT2NUM(42)).is_nil());
  ASSERT_EQUAL(false, Object(Qfalse).is_nil());
  ASSERT_EQUAL(true, Object(Qnil).is_nil());
  ASSERT_EQUAL(false, Object(Qundef).is_nil());
}

TESTCASE(implicit_conversion_to_value)
{
  // Compilers (g++, msvc) can't handle constructor-style inside the assert, which
  // is why we use cast-style here.
  ASSERT_EQUAL(Qtrue, (VALUE)Object(Qtrue));
  ASSERT_EQUAL(INT2NUM(42), (VALUE)Object(INT2NUM(42)));
  ASSERT_EQUAL(Qfalse, (VALUE)Object(Qfalse));
  ASSERT_EQUAL(Qnil, (VALUE)Object(Qnil));
  ASSERT_EQUAL(Qundef, (VALUE)Object(Qundef));
}

TESTCASE(explicit_conversion_to_value)
{
  ASSERT_EQUAL(Qtrue, Object(Qtrue).value());
  ASSERT_EQUAL(INT2NUM(42), Object(INT2NUM(42)).value());
  ASSERT_EQUAL(Qfalse, Object(Qfalse).value());
  ASSERT_EQUAL(Qnil, Object(Qnil).value());
  ASSERT_EQUAL(Qundef, Object(Qundef).value());
}

TESTCASE(class_of)
{
  ASSERT_EQUAL(Class(rb_cObject), Class(rb_cObject).call("new").class_of());
  ASSERT_EQUAL(Class(rb_cFloat), Object(rb_float_new(42.0)).class_of());
}

TESTCASE(compare)
{
  ASSERT_EQUAL(0, Object(INT2NUM(42)).compare(Object(INT2NUM(42))));
  ASSERT_EQUAL(-1, Object(INT2NUM(42)).compare(Object(INT2NUM(43))));
  ASSERT_EQUAL(1, Object(INT2NUM(42)).compare(Object(INT2NUM(41))));
}

TESTCASE(to_s)
{
  ASSERT_EQUAL(String("42"), Object(INT2NUM(42)).to_s());
}

TESTCASE(inspect)
{
  ASSERT_EQUAL(String("42"), Object(INT2NUM(42)).inspect());
  ASSERT_EQUAL(String("\"foo\""), Object(rb_str_new2("foo")).inspect());
}

TESTCASE(freeze)
{
  Object o(Class(rb_cObject).call("new"));
  ASSERT(!OBJ_FROZEN(o.value()));
  o.freeze();
  ASSERT(OBJ_FROZEN(o.value()));
}

TESTCASE(is_frozen)
{
  Object o(Class(rb_cObject).call("new"));
  ASSERT(!o.is_frozen());
  rb_obj_freeze(o);
  ASSERT(o.is_frozen());
}

TESTCASE(instance_eval)
{
  Object o(Class(rb_cObject).call("new"));
  o.iv_set("@foo", 42);
  ASSERT_EQUAL(detail::to_ruby(42), o.instance_eval("@foo").value());
}

TESTCASE(rb_type)
{
  ASSERT_EQUAL(T_TRUE, Object(Qtrue).rb_type());
  ASSERT_EQUAL(T_FIXNUM, Object(INT2NUM(42)).rb_type());
  ASSERT_EQUAL(T_FALSE, Object(Qfalse).rb_type());
  ASSERT_EQUAL(T_NIL, Object(Qnil).rb_type());
  ASSERT_EQUAL(T_UNDEF, Object(Qundef).rb_type());
}

TESTCASE(call_no_arguments)
{
  Object three = Object(detail::to_ruby(3)).call("to_s");
  ASSERT_EQUAL(String("3"), three);
}

TESTCASE(call_return_rice_object)
{
  Object three = Object(detail::to_ruby(1)).call("+", 2);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), three);
}

TESTCASE(call_with_keywords)
{
  Module kernel = Module("Kernel");


  Hash keywords;
  keywords[":exception"] = false;
  Object result = kernel.call("Integer", "charlie", keywords);
  ASSERT_EQUAL(Qnil, result.value());

  keywords[":exception"] = true;

  ASSERT_EXCEPTION_CHECK(
    Exception,
    kernel.call("Integer", "charlie", keywords),
    ASSERT_EQUAL("invalid value for Integer(): \"charlie\"", ex.what())
  );
}

TESTCASE(const_set_get_by_id)
{
  Class c(anonymous_class());
  Object v1 = detail::to_ruby(42);
  Object v2 = c.const_set(rb_intern("FOO"), v1);
  ASSERT_EQUAL(v1, v2);
  ASSERT_EQUAL(v1, c.const_get(rb_intern("FOO")));
}

TESTCASE(const_set_get_by_identifier)
{
  Class c(anonymous_class());
  Object v1 = detail::to_ruby(42);
  Object v2 = c.const_set(Identifier("FOO"), v1);
  ASSERT_EQUAL(v1, v2);
  ASSERT_EQUAL(v1, c.const_get(Identifier("FOO")));
}

TESTCASE(const_set_get_by_string)
{
  Class c(anonymous_class());
  Object v1 = detail::to_ruby(42);
  Object v2 = c.const_set("FOO", v1);
  ASSERT_EQUAL(v1, v2);
  ASSERT_EQUAL(v1, c.const_get("FOO"));
}

TESTCASE(remove_const)
{
  Module m(anonymous_module());
  Object v = detail::to_ruby(42);
  m.const_set("FOO", v);
  ASSERT_EQUAL(v, m.const_get("FOO"));
  m.remove_const("FOO");
  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.const_get("FOO"),
    ASSERT_EQUAL(
      Object(rb_eNameError),
      Object(CLASS_OF(ex.value()))
    )
  );
}

TESTCASE(test_mark)
{
  Object o(INT2NUM(42));
  rb_gc_start();
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(o.value()));
}