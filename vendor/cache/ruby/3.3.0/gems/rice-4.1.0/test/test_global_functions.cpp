#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(GlobalFunction);

SETUP(GlobalFunction)
{
  embed_ruby();
}

namespace {

  bool no_args()
  {
    return true;
  }

  int int_arg(int arg)
  {
    return 2 * arg;
  }
}

TESTCASE(no_args)
{
  define_global_function("no_args", &no_args);
  Module m = Module(rb_mKernel);
  Object result = m.call("no_args");
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(no_args_lambda)
{
  define_global_function("no_args", []()
    {
      return no_args();
    });

  Module m = Module(rb_mKernel);
  Object result = m.call("no_args");
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(int_arg)
{
  define_global_function("method_with_args", &int_arg);
  Module m = Module(rb_mKernel);
  Object result = m.call("method_with_args", 10);
  ASSERT_EQUAL(20, detail::From_Ruby<int>().convert(result));
}

TESTCASE(int_arg_lambda)
{
  define_global_function("method_with_args", [](int value)
    {
      return int_arg(value);
    });

  Module m = Module(rb_mKernel);
  Object result = m.call("method_with_args", 10);
  ASSERT_EQUAL(20, detail::From_Ruby<int>().convert(result));
}

namespace
{
  int defaults_method_one_arg1;
  int defaults_method_one_arg2;
  bool defaults_method_one_arg3 = false;

  void defaults_method_one(int arg1, int arg2 = 3, bool arg3 = true)
  {
    defaults_method_one_arg1 = arg1;
    defaults_method_one_arg2 = arg2;
    defaults_method_one_arg3 = arg3;
  }

  int defaults_returns(int arg1, int arg2 = 3)
  {
    return arg1 * arg2;
  }
}

TESTCASE(default_arguments_for_define_global_function)
{
  define_global_function("foo", &defaults_method_one, Arg("arg1"), Arg("arg2") = (int)3, Arg("arg3") = (bool)true);
  Module m(rb_mKernel);

  m.call("foo", 2);

  ASSERT_EQUAL(2, defaults_method_one_arg1);
  ASSERT_EQUAL(3, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  m.call("foo", 11, 10);

  ASSERT_EQUAL(11, defaults_method_one_arg1);
  ASSERT_EQUAL(10, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  m.call("foo", 22, 33, false);

  ASSERT_EQUAL(22, defaults_method_one_arg1);
  ASSERT_EQUAL(33, defaults_method_one_arg2);
  ASSERT(!defaults_method_one_arg3);
}

TESTCASE(default_arguments_for_define_global_function_and_returning)
{
  define_global_function("foo_ret", &defaults_returns, Arg("arg1"), Arg("arg2") = (int)3);
  Module m(rb_mKernel);

  Object o = m.call("foo_ret", 2);
  ASSERT_EQUAL(INT2NUM(6), o.value());

  o = m.call("foo_ret", 5, 10);
  ASSERT_EQUAL(INT2NUM(50), o.value());
}

namespace {
  int the_one_default_arg = 0;
  void method_with_one_default_arg(int num = 4) {
    the_one_default_arg = num;
  }
}

TESTCASE(single_default_argument)
{
  define_global_function("foo", &method_with_one_default_arg, (Arg("num") = (int)4));
  Module m(rb_mKernel);
  m.call("foo");
  ASSERT_EQUAL(4, the_one_default_arg);
}
