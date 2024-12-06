#include "unittest.hpp"
#include "embed_ruby.hpp"

#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(Module);

SETUP(Module)
{
  embed_ruby();
}

TESTCASE(FromConstant)
{
  Module m(rb_mEnumerable);
  ASSERT_EQUAL(rb_mEnumerable, m.value());
}

TESTCASE(FromName)
{
  Module m("Enumerable");
  ASSERT_EQUAL(rb_mEnumerable, m.value());
}

namespace
{

class Quite_Silly_Exception
  : public std::exception
{
};

void handle_silly_exception(Quite_Silly_Exception const & ex)
{
  throw Exception(rb_eRuntimeError, "SILLY");
}

void throw_silly_exception(Object self)
{
  throw Quite_Silly_Exception();
}

} // namespace

TESTCASE(add_handler)
{
  register_handler<Quite_Silly_Exception>(handle_silly_exception);

  Module m(anonymous_module());
  m.define_singleton_method("foo", throw_silly_exception);
  Object exc = m.module_eval("begin; foo; rescue Exception; $!; end");
  ASSERT_EQUAL(rb_eRuntimeError, CLASS_OF(exc));
  Exception ex(exc);
  ASSERT_EQUAL(String("SILLY"), String(ex.what()));
}

namespace
{

bool some_function()
{
  return true;
}

Object some_method(Object o)
{
  return o;
}

int function_int(int i)
{
  return i;
}

int method_int(Object object, int i)
{
  return i;
}

} // namespace

TESTCASE(define_method)
{
  Module m(anonymous_module());
  m.define_method("some_method", some_method);
  
  Object o = m.module_eval("$o = Object.new");
  Object result = m.module_eval(R"EOS($o.extend(self)
                                        $o.some_method)EOS");
  ASSERT_EQUAL(o, result);
}

TESTCASE(define_singleton_method)
{
  Module m(anonymous_module());
  m.define_singleton_method("some_method", some_method);
  Object result = m.call("some_method");
  ASSERT_EQUAL(m, result);
}

TESTCASE(define_module_function)
{
  Module m(anonymous_module());
  m.define_module_function("some_function", some_function);

  Object result = m.module_eval(R"EOS(o = Object.new
                                   o.extend(self)
                                   o.instance_eval do
                                     some_function
                                   end)EOS");

  ASSERT_EQUAL(Qtrue, result.value());
  result = m.call("some_function");
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(define_module_does_not_leak_method_to_Object)
{
  Module m = define_module("TestModule");
  m.define_module_function("test_module_function", &some_method);

  Module runner(anonymous_module());
  ASSERT_EXCEPTION_CHECK(
    Exception,
    runner.instance_eval("Object.test_module_function"),
    ASSERT_EQUAL(
      Object(rb_eNoMethodError),
      Object(CLASS_OF(ex.value()))
    )
  );
}

TESTCASE(define_function_int)
{
  Module m(anonymous_module());
  m.define_function("foo", function_int);
  Object result = m.module_eval("o = Object.new; o.extend(self); o.foo(42)");
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(define_method_int)
{
  Module m(anonymous_module());
  m.define_method("foo", method_int);
  Object result = m.module_eval("o = Object.new; o.extend(self); o.foo(42)");
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(define_singleton_method_int)
{
  Module m(anonymous_module());
  m.define_singleton_method("foo", method_int);
  Object result = m.call("foo", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(define_singleton_function_int)
{
  Module m(anonymous_module());
  m.define_singleton_function("foo", function_int);
  Object result = m.call("foo", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(define_module_function_int)
{
  Module m(anonymous_module());
  m.define_module_function("foo", function_int);
  Object result = m.module_eval("o = Object.new; o.extend(self); o.instance_eval { foo(42) }");
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));

  result = m.call("foo", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(method_int_passed_no_args)
{
  Module m(anonymous_module());
  m.define_method("foo", method_int);
  ASSERT_EXCEPTION_CHECK(
      Exception,
      m.module_eval("o = Object.new; o.extend(self); o.foo"),
      ASSERT_EQUAL(
          Object(rb_eArgError),
          Object(CLASS_OF(ex.value()))
          )
      );
}

TESTCASE(define_singleton_method_int_foo)
{
  Module m(anonymous_module());
  m.define_singleton_method("method_int", method_int);

  Object result = m.call("method_int", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(include_module)
{
  Module m(anonymous_module());
  Module & m2(m.include_module(rb_mEnumerable));
  ASSERT_EQUAL(&m, &m2);
  Array ancestors(m.ancestors());
  Array expected_ancestors;
  expected_ancestors.push(m);
  expected_ancestors.push(Module(rb_mEnumerable));
  ASSERT_EQUAL(expected_ancestors, ancestors);
}

TESTCASE(mod_name_anonymous)
{
  Module m(anonymous_module());
  ASSERT_EQUAL(String(""), m.name());
}

// Tests for default arguments
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
}

TESTCASE(define_method_default_arguments)
{
  Module m(anonymous_module());
  m.define_function("foo", &defaults_method_one, Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true);

  Object o = m.module_eval("o = Object.new; o.extend(self); o");
  o.call("foo", 2);

  ASSERT_EQUAL(2, defaults_method_one_arg1);
  ASSERT_EQUAL(3, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  o.call("foo", 11, 10);

  ASSERT_EQUAL(11, defaults_method_one_arg1);
  ASSERT_EQUAL(10, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  o.call("foo", 22, 33, false);

  ASSERT_EQUAL(22, defaults_method_one_arg1);
  ASSERT_EQUAL(33, defaults_method_one_arg2);
  ASSERT(!defaults_method_one_arg3);
}

TESTCASE(default_arguments_still_throws_argument_error)
{
  Module m(anonymous_module());
  m.define_function("foo", &defaults_method_one, Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true);

  ASSERT_EXCEPTION_CHECK(
      Exception,
      m.module_eval("o = Object.new; o.extend(self); o.foo()"),
      ASSERT_EQUAL(
          Object(rb_eArgError),
          Object(CLASS_OF(ex.value()))
          )
      );

  ASSERT_EXCEPTION_CHECK(
      Exception,
      m.module_eval("o = Object.new; o.extend(self); o.foo(3, 4, false, 17)"),
      ASSERT_EQUAL(
          Object(rb_eArgError),
          Object(CLASS_OF(ex.value()))
          )
      );
}

namespace {
  int the_one_default_arg = 0;
  void method_with_one_default_arg(int num = 4) {
    the_one_default_arg = num;
  }
}

TESTCASE(defining_methods_with_single_default_argument)
{
  // define_method
  Module m(anonymous_module());
  m.define_function("foo", &method_with_one_default_arg, (Arg("num") = 4));
  m.module_eval("o = Object.new; o.extend(self); o.foo()");
  ASSERT_EQUAL(4, the_one_default_arg);

  the_one_default_arg = 0;

  // define_singleton_method
  Class c(anonymous_class());
  c.define_singleton_function("foo", &method_with_one_default_arg, (Arg("num") = 4));
  c.call("foo");
  ASSERT_EQUAL(4, the_one_default_arg);

  the_one_default_arg = 0;

  // define_module_function
  m.define_module_function("foo2", &method_with_one_default_arg, (Arg("num") = 4));

  m.call("foo2");
  ASSERT_EQUAL(4, the_one_default_arg);
}

TESTCASE(default_arguments_for_define_singleton_method)
{
  Class c(anonymous_class());
  c.define_singleton_function("foo", &defaults_method_one, Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true);

  c.call("foo", 2);

  ASSERT_EQUAL(2, defaults_method_one_arg1);
  ASSERT_EQUAL(3, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  c.call("foo", 11, 10);

  ASSERT_EQUAL(11, defaults_method_one_arg1);
  ASSERT_EQUAL(10, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  c.call("foo", 22, 33, false);

  ASSERT_EQUAL(22, defaults_method_one_arg1);
  ASSERT_EQUAL(33, defaults_method_one_arg2);
  ASSERT(!defaults_method_one_arg3);
}

TESTCASE(default_arguments_for_define_module_function)
{
  Module m(anonymous_module());
  m.define_module_function("foo", &defaults_method_one, Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true);

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

namespace {
  std::string with_defaults_and_references_x;
  bool with_defaults_and_references_doIt;

  void with_defaults_and_references(std::string const& x, bool doIt = false)
  {
    with_defaults_and_references_x = x;
    with_defaults_and_references_doIt = doIt;
  }
}

TESTCASE(define_method_works_with_reference_arguments)
{
  Module m(anonymous_module());
  m.define_module_function("foo", &with_defaults_and_references,
      Arg("x"), Arg("doIt") = false);

  m.call("foo", "test");

  ASSERT_EQUAL("test", with_defaults_and_references_x);
  ASSERT(!with_defaults_and_references_doIt);
}

namespace {
  class ReturnTest { };

  class Factory {
    public:
      Factory() { returnTest_ = new ReturnTest(); }

      const ReturnTest& getReturnTest() const {
        return *returnTest_;
      }

     private:
      const ReturnTest* returnTest_;
  };
}

TESTCASE(define_method_works_with_const_reference_return)
{
  define_class<ReturnTest>("ReturnTest")
    .define_constructor(Constructor<ReturnTest>());

  define_class<Factory>("Factory")
    .define_constructor(Constructor<Factory>())
    .define_method("get_return_test", &Factory::getReturnTest);

  Module m(anonymous_module());

  Object result = m.module_eval("Factory.new.get_return_test");

  ASSERT_EQUAL("ReturnTest", result.class_of().name().c_str());
}

namespace
{
  float with_reference_defaults_x;
  std::string with_reference_defaults_str;

  void with_reference_defaults(float x, std::string const& str = std::string("testing"))
  {
    with_reference_defaults_x = x;
    with_reference_defaults_str = str;
  }
}

TESTCASE(define_method_works_with_reference_const_default_values)
{
  Module m(anonymous_module());
  m.define_module_function("bar", &with_reference_defaults,
      Arg("x"), Arg("str") = std::string("testing"));

  m.call("bar", 3);

  ASSERT_EQUAL(3, with_reference_defaults_x);
  ASSERT_EQUAL("testing", with_reference_defaults_str);
}

namespace
{
  int with_pointers_x;
  std::string with_pointers_str;

  void with_pointers(int* x, std::string const* str)
  {
    with_pointers_x = *x;
    with_pointers_str = *str;
  }
}

TESTCASE(define_method_works_with_pointers)
{
  Module m(anonymous_module());
  m.define_module_function("bar", &with_pointers);

  m.call("bar", 3, "testing");

  ASSERT_EQUAL(3, with_pointers_x);
  ASSERT_EQUAL("testing", with_pointers_str);
}

namespace
{
  int intValue;
  bool boolValue;
  float floatValue;
  double doubleValue;

  void withPointers(const int* anInt, const bool* aBool, const float* aFloat, const double* aDouble)
  {
    intValue = *anInt;
    boolValue = *aBool;
    floatValue = *aFloat;
    doubleValue = *aDouble;
  }

  void withReferences(const int& anInt, const bool& aBool, const float& aFloat, const double& aDouble)
  {
    intValue = anInt;
    boolValue = aBool;
    floatValue = aFloat;
    doubleValue = aDouble;
  }
}

TESTCASE(pointers)
{
  define_global_function("with_pointers", &withPointers);

  Module m = define_module("TestingModule");

  std::string code = "with_pointers(32, true, 33.0, 34.0)";
  m.module_eval(code);

  ASSERT_EQUAL(intValue, 32);
  ASSERT_EQUAL(boolValue, true);
  ASSERT_EQUAL(floatValue, 33.0);
  ASSERT_EQUAL(doubleValue, 34.0);
}

TESTCASE(references)
{
  define_global_function("with_references", &withReferences);

  Module m = define_module("TestingModule");

  std::string code = "with_references(42, true, 43.0, 44.0)";
  m.module_eval(code);

  ASSERT_EQUAL(intValue, 42);
  ASSERT_EQUAL(boolValue, true);
  ASSERT_EQUAL(floatValue, 43.0);
  ASSERT_EQUAL(doubleValue, 44.0);
}