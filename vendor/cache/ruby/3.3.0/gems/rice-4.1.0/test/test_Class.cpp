#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Class);

SETUP(Class)
{
  embed_ruby();
}

TESTCASE(construct)
{
  Class c(rb_cObject);
  ASSERT_EQUAL(rb_cObject, c.value());
}

TESTCASE(undef_creation_funcs)
{
  Class c(anonymous_class());
  Class & c2(c.undef_creation_funcs());
  ASSERT_EQUAL(&c, &c2);
  ASSERT_EXCEPTION_CHECK(
      Exception,
      c.call("new"),
      ASSERT_EQUAL(rb_eTypeError, ex.class_of())
      );
}

TESTCASE(include_module)
{
  Class c(anonymous_class());
  Class & c2(c.include_module(rb_mEnumerable));
  ASSERT_EQUAL(&c, &c2);
  Array ancestors(c.ancestors());
  Array expected_ancestors;
  expected_ancestors.push(c);
  expected_ancestors.push(Module(rb_mEnumerable));
  expected_ancestors.push(Module(rb_cObject));
  expected_ancestors.push(Module(rb_mKernel));
#ifdef RUBY_VM
  expected_ancestors.push(Module(rb_cBasicObject));
#endif
  ASSERT_EQUAL(expected_ancestors, ancestors);
}

namespace
{
  bool some_function()
  {
    return true;
  }

  Object some_method(Object self)
  {
    return self;
  }
}

TESTCASE(methods)
{
  Class c(anonymous_class());
  c.define_function("some_function", &some_function);
  c.define_method("some_method", &some_method);

  Object o = c.call("new");
  Object result = o.call("some_function");
  ASSERT_EQUAL(Qtrue, result.value());

  result = o.call("some_method");
  ASSERT_EQUAL(o, result);
}

TESTCASE(method_lambdas)
{
  Class c(anonymous_class());
  c.define_function("some_function", []()
    {
      return some_function();
    });
  c.define_method("some_method", [](VALUE self)
  {
    return some_method(self);
  });

  Object o = c.call("new");
  Object result = o.call("some_function");
  ASSERT_EQUAL(Qtrue, result.value());

  result = o.call("some_method");
  ASSERT_EQUAL(o, result);
}

TESTCASE(singleton_methods)
{
  Class c(anonymous_class());
  c.define_singleton_method("some_method", &some_method);

  Object result = c.call("some_method");
  ASSERT_EQUAL(c, result);
}

TESTCASE(singleton_method_lambdas)
{
  Class c(anonymous_class());
  c.define_singleton_method("some_method", [](VALUE self)
    {
      return some_method(self);
    });

  Object result = c.call("some_method");
  ASSERT_EQUAL(c, result);
}

TESTCASE(module_function)
{
  // module_function only works with Module, not Class
  Class c(anonymous_class());
  ASSERT_EXCEPTION_CHECK(
    std::runtime_error,
    c.define_module_function("some_function", &some_function),
    ASSERT_EQUAL("can only define module functions for modules", ex.what())
  );
}

namespace
{
  class Silly_Exception
    : public std::exception
  {
  };

  void handle_silly_exception(Silly_Exception const & ex)
  {
    throw Exception(rb_eRuntimeError, "SILLY");
  }

  void throw_silly_exception()
  {
    throw Silly_Exception();
  }
}

TESTCASE(add_handler)
{
  register_handler<Silly_Exception>(handle_silly_exception);

  Class c(rb_cObject);
  c.define_function("foo", throw_silly_exception);

  Object exc = detail::protect(rb_eval_string, "begin; foo; rescue Exception; $!; end");
  ASSERT_EQUAL(rb_eRuntimeError, CLASS_OF(exc));
  Exception ex(exc);
  ASSERT_EQUAL("SILLY", ex.what());
}

TESTCASE(define_class)
{
  Class object(rb_cObject);
  if(object.const_defined("Foo"))
  {
    object.remove_const("Foo");
  }

  Class c = define_class("Foo1");

  ASSERT(c.is_a(rb_cClass));
  ASSERT_EQUAL(c, object.const_get("Foo1"));
}

TESTCASE(define_class_under)
{
  Class object(rb_cObject);
  if(object.const_defined("Foo"))
  {
    object.remove_const("Foo");
  }

  Module math(rb_mMath);
  if(math.const_defined("Foo"))
  {
    math.remove_const("Foo");
  }

  Class c = define_class_under(math, "Foo");

  ASSERT(c.is_a(rb_cClass));
  ASSERT_EQUAL(c, math.const_get("Foo"));
  ASSERT(!object.const_defined("Foo"));
}

TESTCASE(module_define_class)
{
  Class object(rb_cObject);
  if(object.const_defined("Foo"))
  {
    object.remove_const("Foo");
  }

  Module math(rb_mMath);
  if(math.const_defined("Foo"))
  {
    math.remove_const("Foo");
  }

  Class c = define_class_under(math, "Foo");

  ASSERT(c.is_a(rb_cClass));
  ASSERT_EQUAL(c, math.const_get("Foo"));
  ASSERT(!object.const_defined("Foo"));
}

namespace
{
  int defaults_method_one_arg1;
  int defaults_method_one_arg2;
  bool defaults_method_one_arg3 = false;

  class DefaultArgs
  {
    public:
      void defaults_method_one(int arg1, int arg2 = 3, bool arg3 = true)
      {
        defaults_method_one_arg1 = arg1;
        defaults_method_one_arg2 = arg2;
        defaults_method_one_arg3 = arg3;
      }
  };
}

TESTCASE(define_method_default_arguments)
{
  Class c = define_class<DefaultArgs>("DefaultArgs")
              .define_constructor(Constructor<DefaultArgs>())
              .define_method("with_defaults",
                  &DefaultArgs::defaults_method_one,
                  Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true);

  Object o = c.call("new");
  o.call("with_defaults", 2);

  ASSERT_EQUAL(2, defaults_method_one_arg1);
  ASSERT_EQUAL(3, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  o.call("with_defaults", 11, 10);

  ASSERT_EQUAL(11, defaults_method_one_arg1);
  ASSERT_EQUAL(10, defaults_method_one_arg2);
  ASSERT(defaults_method_one_arg3);

  o.call("with_defaults", 22, 33, false);

  ASSERT_EQUAL(22, defaults_method_one_arg1);
  ASSERT_EQUAL(33, defaults_method_one_arg2);
  ASSERT(!defaults_method_one_arg3);
}

namespace
{
  int func1 = 0;
  int func2 = 0;

  int function1(int aValue)
  {
    func1 = aValue;
    return func1;
  }

  int function2(int aValue)
  {
    func2 = aValue;
    return func2;
  }
}

TESTCASE(same_function_signature)
{
  Class c = define_class("FunctionSignatures")
    .define_singleton_function("function1", &function1)
    .define_singleton_function("function2", &function2);

  c.call("function1", 5);
  ASSERT_EQUAL(5, func1);

  c.call("function2", 6);
  ASSERT_EQUAL(6, func2);
}

namespace
{
  VALUE someValue;

  void value_parameter(VALUE value)
  {
    someValue = value;
  }

  VALUE value_return()
  {
    return rb_ary_new_from_args(3, Qnil, Qtrue, Qfalse);
  }
}

TESTCASE(value_parameter)
{
  define_global_function("value_parameter", &value_parameter, Arg("value").setValue());

  Module m = define_module("TestingModule");
  
  std::string code = R"($object = Object.new)";
  Object object = m.module_eval(code);

  code = R"(value_parameter($object))";
  m.module_eval(code);

  ASSERT_EQUAL(someValue, object.value());
}

TESTCASE(value_return)
{
  define_global_function("value_return", &value_return, Return().setValue());

  Module m = define_module("TestingModule");

  VALUE value = m.module_eval("value_return");
  detail::protect(rb_check_type, value, (int)T_ARRAY);

  ASSERT_EQUAL(3, Array(value).size());
}
