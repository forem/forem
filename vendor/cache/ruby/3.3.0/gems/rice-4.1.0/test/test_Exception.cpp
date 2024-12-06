#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Exception);

SETUP(Exception)
{
  embed_ruby();
}

TESTCASE(construct_from_exception_object)
{
  VALUE v = detail::protect(rb_exc_new2, rb_eRuntimeError, "foo");
  Exception ex(v);
  ASSERT_EQUAL(ex.value(), v);
}

TESTCASE(copy_construct)
{
  VALUE v = detail::protect(rb_exc_new2, rb_eRuntimeError, "foo");
  Exception ex1(v);
  Exception ex2(v);
  ASSERT_EQUAL(ex2.value(), v);
}

TESTCASE(construct_from_format_string)
{
  Exception ex(rb_eRuntimeError, "%s", "foo");
  ASSERT_EQUAL(rb_eRuntimeError, ex.class_of());
}

TESTCASE(message)
{
  Exception ex(rb_eRuntimeError, "%s", "foo");
  ASSERT_EQUAL("foo", ex.what());
}

TESTCASE(what)
{
  const char* foo = "foo";
  Exception ex(rb_eRuntimeError, "%s", "foo");
  ASSERT_EQUAL(foo, ex.what());
}

