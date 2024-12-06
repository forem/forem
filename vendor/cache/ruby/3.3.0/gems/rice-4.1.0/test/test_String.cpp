#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(String);

SETUP(String)
{
  embed_ruby();
}

TESTCASE(default_construct)
{
  String s;
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("", RSTRING_PTR(s.value()));
}

TESTCASE(construct_from_value)
{
  String s(rb_str_new2("foo"));
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo", RSTRING_PTR(s.value()));
}

TESTCASE(construct_from_object)
{
  Object o(rb_str_new2("foo"));
  String s(o);
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo", RSTRING_PTR(s.value()));
}

TESTCASE(construct_from_identifier)
{
  String s(Identifier("foo"));
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo", RSTRING_PTR(s.value()));
}

TESTCASE(construct_from_c_string)
{
  String s("foo");
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo", RSTRING_PTR(s.value()));
}

TESTCASE(construct_from_std_string)
{
  String s(std::string("foo"));
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo", RSTRING_PTR(s.value()));
}

TESTCASE(format)
{
  String s(String::format("%s %d", "foo", 42));
  ASSERT_EQUAL(T_STRING, rb_type(s));
  ASSERT_EQUAL("foo 42", RSTRING_PTR(s.value()));
}

TESTCASE(length)
{
  String s("foo");
  ASSERT_EQUAL(3u, s.length());
}

TESTCASE(bracket)
{
  String s("foo");
  ASSERT_EQUAL('f', s[0]);
  ASSERT_EQUAL('o', s[1]);
  ASSERT_EQUAL('o', s[2]);
}

TESTCASE(c_str)
{
  String s("foo");
  ASSERT_EQUAL(RSTRING_PTR(s.value()), s.c_str());
}

TESTCASE(str)
{
  String s("foo");
  ASSERT_EQUAL(std::string("foo"), s.str());
}

TESTCASE(intern)
{
  String s("foo");
  ASSERT_EQUAL(Identifier("foo"), s.intern());
}

/**
 * Issue 59 - Copy constructor compilation problem.
 */

namespace {
  void testStringArg(Object self, String string) {
  }
}

TESTCASE(use_string_in_wrapped_function) {
  define_global_function("test_string_arg", &testStringArg);
}
