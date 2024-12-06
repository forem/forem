#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Struct);

namespace
{
  Struct define_3d_point()
  {
    static Struct rb_cPoint = define_struct()
      .define_member("x")
      .define_member("y")
      .define_member("z")
      .initialize(rb_mKernel, "Point");
    return rb_cPoint;
  }
}

SETUP(Struct)
{
  embed_ruby();
}

TESTCASE(default_construct)
{
  Struct s;
  ASSERT_EQUAL(0, s.members().size());
  // can't call rb_struct_s_members, because this isn't a struct yet
}

TESTCASE(initialize)
{
  Struct s(define_3d_point());
  Array members(rb_struct_s_members(s));
  ASSERT_EQUAL(3, members.size());
  ASSERT_EQUAL("x", Symbol(members[0]).c_str());
  ASSERT_EQUAL("y", Symbol(members[1]).c_str());
  ASSERT_EQUAL("z", Symbol(members[2]).c_str());
}

TESTCASE(copy_construct)
{
  Struct s(define_3d_point());
  Struct s2(s);
  Array members(rb_struct_s_members(s2));
  ASSERT_EQUAL(3, members.size());
  ASSERT_EQUAL("x", Symbol(members[0]).c_str());
  ASSERT_EQUAL("y", Symbol(members[1]).c_str());
  ASSERT_EQUAL("z", Symbol(members[2]).c_str());
}

TESTCASE(new_instance_no_args)
{
  Struct s(define_3d_point());
  Struct::Instance p(s.new_instance());
  ASSERT_EQUAL(Rice::Nil, Object(rb_struct_getmember(p, rb_intern("x"))));
  ASSERT_EQUAL(Rice::Nil, Object(rb_struct_getmember(p, rb_intern("y"))));
  ASSERT_EQUAL(Rice::Nil, Object(rb_struct_getmember(p, rb_intern("z"))));
}

TESTCASE(new_instance_with_args)
{
  int a[] = { 1, 2, 3 };
  Array args(a);
  Struct s(define_3d_point());
  Struct::Instance p(s.new_instance(args));
  ASSERT_EQUAL(detail::to_ruby(1), rb_struct_getmember(p, rb_intern("x")));
  ASSERT_EQUAL(detail::to_ruby(2), rb_struct_getmember(p, rb_intern("y")));
  ASSERT_EQUAL(detail::to_ruby(3), rb_struct_getmember(p, rb_intern("z")));
}

/*TESTCASE(swap)
{
  Struct s(define_3d_point());
  Struct s2;
  s2.swap(s);

  try
  {
    Array members(rb_struct_s_members(s2));
    ASSERT_EQUAL(3, members.size());
    ASSERT_EQUAL("x", Symbol(members[0]).c_str());
    ASSERT_EQUAL("y", Symbol(members[1]).c_str());
    ASSERT_EQUAL("z", Symbol(members[2]).c_str());
  }
  catch(...)
  {
    s2.swap(s);
    throw;
  }

  s2.swap(s);
}*/

TESTCASE(members)
{
  Struct s(define_3d_point());
  Array members(s.members());
  ASSERT_EQUAL(3, members.size());
  ASSERT_EQUAL("x", Symbol(members[0]).c_str());
  ASSERT_EQUAL("y", Symbol(members[1]).c_str());
  ASSERT_EQUAL("z", Symbol(members[2]).c_str());
}

TESTCASE(construct_instance)
{
  int a[] = { 1, 2, 3 };
  Array args(a);
  Struct s(define_3d_point());
  Struct::Instance p(s, args);
  ASSERT_EQUAL(detail::to_ruby(1), rb_struct_getmember(p, rb_intern("x")));
  ASSERT_EQUAL(detail::to_ruby(2), rb_struct_getmember(p, rb_intern("y")));
  ASSERT_EQUAL(detail::to_ruby(3), rb_struct_getmember(p, rb_intern("z")));
}

TESTCASE(wrap_instance)
{
  Struct s(define_3d_point());
  Object o = s.instance_eval("new(1, 2, 3)");
  Struct::Instance p(s, o);
  ASSERT_EQUAL(detail::to_ruby(1), rb_struct_getmember(p, rb_intern("x")));
  ASSERT_EQUAL(detail::to_ruby(2), rb_struct_getmember(p, rb_intern("y")));
  ASSERT_EQUAL(detail::to_ruby(3), rb_struct_getmember(p, rb_intern("z")));
}

TESTCASE(instance_bracket_identifier)
{
  int a[] = { 1, 2, 3 };
  Array args(a);
  Struct s(define_3d_point());
  Struct::Instance p(s, args);
  ASSERT_EQUAL(detail::to_ruby(1), p[Identifier("x")].value());
  ASSERT_EQUAL(detail::to_ruby(2), p[Identifier("y")].value());
  ASSERT_EQUAL(detail::to_ruby(3), p[Identifier("z")].value());
}

TESTCASE(instance_bracket_name)
{
  int a[] = { 1, 2, 3 };
  Array args(a);
  Struct s(define_3d_point());
  Struct::Instance p(s, args);
  ASSERT_EQUAL(detail::to_ruby(1), p["x"].value());
  ASSERT_EQUAL(detail::to_ruby(2), p["y"].value());
  ASSERT_EQUAL(detail::to_ruby(3), p["z"].value());
}

TESTCASE(instance_bracket_index)
{
  int a[] = { 1, 2, 3 };
  Array args(a);
  Struct s(define_3d_point());
  Struct::Instance p(s, args);
  ASSERT_EQUAL(detail::to_ruby(1), p[0].value());
  ASSERT_EQUAL(detail::to_ruby(2), p[1].value());
  ASSERT_EQUAL(detail::to_ruby(3), p[2].value());
}

TESTCASE(instance_swap)
{
  Struct s(define_3d_point());

  int a1[] = { 1, 2, 3 };
  Array args1(a1);
  Struct::Instance p1(s, args1);

  int a2[] = { 4, 5, 6 };
  Array args2(a2);
  Struct::Instance p2(s, args2);

  std::swap(p1, p2);

  ASSERT_EQUAL(detail::to_ruby(4), rb_struct_getmember(p1, rb_intern("x")));
  ASSERT_EQUAL(detail::to_ruby(5), rb_struct_getmember(p1, rb_intern("y")));
  ASSERT_EQUAL(detail::to_ruby(6), rb_struct_getmember(p1, rb_intern("z")));

  ASSERT_EQUAL(detail::to_ruby(1), rb_struct_getmember(p2, rb_intern("x")));
  ASSERT_EQUAL(detail::to_ruby(2), rb_struct_getmember(p2, rb_intern("y")));
  ASSERT_EQUAL(detail::to_ruby(3), rb_struct_getmember(p2, rb_intern("z")));
}

/**
 * Issue 59 - Copy constructor compilation problem.
 */

namespace {
  void testStructArg(Object self, Struct string) {
  }
}

TESTCASE(use_struct_in_wrapped_function) {
  define_global_function("test_struct_arg", &testStructArg);
}
