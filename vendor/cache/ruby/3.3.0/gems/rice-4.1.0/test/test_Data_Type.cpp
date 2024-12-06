#include <assert.h> 

#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(Data_Type);

SETUP(Data_Type)
{
  embed_ruby();
}

/**
 * The tests here are for the feature of taking an instance
 * of a Ruby-subclass of a Rice wrapped class and passing
 * that instance back into the Rice wrapper. While that
 * might be confusing, the test code is pretty straight foward
 * to see what we're talking about.
 */

namespace
{
  class MyClass
  {
  public:
    static inline bool no_return_no_arg_called = false;
    static inline bool no_arg_called = false;
    static inline bool int_arg_called = false;
    static inline bool multiple_args_called = false;

    static void reset()
    {
      no_return_no_arg_called = false;
      no_arg_called = false;
      int_arg_called = false;
      multiple_args_called = false;
    }

    static Object singleton_method_object_int(Object object, int anInt)
    {
      return object;
    }

    static int singleton_function_int(int anInt)
    {
      return anInt;
    }

  public:
    MyClass() = default;
    MyClass(const MyClass& other) = delete;
    MyClass(MyClass&& other) = delete;

    void no_return_no_arg()
    {
      no_return_no_arg_called = true;
    }

    bool no_arg()
    {
      no_arg_called = true;
      return true;
    }

    int int_arg(int i)
    {
      int_arg_called = true;
      return i;
    }

    std::string multiple_args(int i, bool b, float f, std::string s, char* c)
    {
      multiple_args_called = true;
      return "multiple_args(" + std::to_string(i) + ", " + std::to_string(b) + ", " +
        std::to_string(f) + ", " + s + ", " + std::string(c) + ")";
    }
  };
} // namespace

TESTCASE(methods_with_member_pointers)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_method("no_return_no_arg", &MyClass::no_return_no_arg)
    .define_method("no_arg", &MyClass::no_arg)
    .define_method("int_arg", &MyClass::int_arg)
    .define_method("multiple_args", &MyClass::multiple_args);

  MyClass::reset();
  Object o = c.call("new");

  Object result = o.call("no_return_no_arg");
  ASSERT(MyClass::no_return_no_arg_called);
  ASSERT_EQUAL(Qnil, result.value());

  result = o.call("no_arg");
  ASSERT(MyClass::no_arg_called);
  ASSERT_EQUAL(Qtrue, result.value());

  result = o.call("int_arg", 42);
  ASSERT(MyClass::int_arg_called);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result.value()));

  result = o.call("multiple_args", 81, true, 7.0, "a string", "a char");
  ASSERT(MyClass::multiple_args_called);
  ASSERT_EQUAL("multiple_args(81, 1, 7.000000, a string, a char)", detail::From_Ruby<std::string>().convert(result.value()));
}

TESTCASE(incorrect_number_of_args)
{
  Class c =
    define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_method("int_arg", &MyClass::int_arg);

  Object o = c.call("new");

  ASSERT_EXCEPTION_CHECK(
    Exception,
    o.call("int_arg", 1, 2),
    ASSERT_EQUAL(rb_eArgError, ex.class_of())
  );
}

TESTCASE(incorrect_no_args)
{
  Class c =
    define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_method("int_arg", &MyClass::int_arg);

  Object o = c.call("new");

  ASSERT_EXCEPTION_CHECK(
    Exception,
    o.call("int_arg"),
    ASSERT_EQUAL(rb_eArgError, ex.class_of())
  );
}

TESTCASE(methods_with_lambdas)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_method("no_return_no_arg", 
        [](MyClass& instance)
        {
          instance.no_return_no_arg();
        })
    .define_method("no_arg",
        [](MyClass& instance)
        {
          return instance.no_arg();
        })
    .define_method("int_arg", 
        [](MyClass& instance, int anInt)
        {
          return instance.int_arg(anInt);
        })
    .define_method("multiple_args",
        [](MyClass& instance, int anInt, bool aBool, float aFloat, std::string aString, char* aChar)
        {
          return instance.multiple_args(anInt, aBool, aFloat, aString, aChar);
        });

  MyClass::reset();
  Object o = c.call("new");

  Object result = o.call("no_return_no_arg");
  ASSERT(MyClass::no_return_no_arg_called);
  ASSERT_EQUAL(Qnil, result.value());

  result = o.call("no_arg");
  ASSERT(MyClass::no_arg_called);
  ASSERT_EQUAL(Qtrue, result.value());

  result = o.call("int_arg", 42);
  ASSERT(MyClass::int_arg_called);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result.value()));

  result = o.call("multiple_args", 81, true, 7.0, "a string", "a char");
  ASSERT(MyClass::multiple_args_called);
  ASSERT_EQUAL("multiple_args(81, 1, 7.000000, a string, a char)", detail::From_Ruby<std::string>().convert(result.value()));
}

TESTCASE(static_singleton_method)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_singleton_method("singleton_method_object_int", &MyClass::singleton_method_object_int);

  MyClass::reset();

  Object result = c.call("singleton_method_object_int", 42);
  ASSERT_EQUAL(c, result);
}

TESTCASE(static_singleton_function)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_singleton_function("singleton_function_int", &MyClass::singleton_function_int);

  MyClass::reset();

  Object result = c.call("singleton_function_int", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

TESTCASE(static_singleton_method_lambda)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_singleton_method("singleton_method_object_int", [](Object object, int anInt)
      {
        return MyClass::singleton_method_object_int(object, anInt);
      });

  MyClass::reset();

  Object result = c.call("singleton_method_object_int", 42);
  ASSERT_EQUAL(c, result);
}

TESTCASE(static_singleton_function_lambda)
{
  Class c = define_class<MyClass>("MyClass")
    .define_constructor(Constructor<MyClass>())
    .define_singleton_function("singleton_function_int", [](int anInt)
      {
        return MyClass::singleton_function_int(anInt);
      });

  MyClass::reset();

  Object result = c.call("singleton_function_int", 42);
  ASSERT_EQUAL(42, detail::From_Ruby<int>().convert(result));
}

namespace {
  class BaseClass
  {
  public:
    BaseClass() {}

    bool some_method()
    {
      return true;
    }

    bool another_method()
    {
      return true;
    }
  };
}

TESTCASE(subclassing)
{
  Module m = define_module("Testing");
  define_class_under<BaseClass>(m, "BaseClass").
    define_constructor(Constructor<BaseClass>()).
    define_method("some_method", &BaseClass::some_method).
    define_method("another_method", &BaseClass::another_method);

    std::string code = R"(class ChildClass < BaseClass
                            def child_method
                              false
                            end

                            def another_method
                              super
                            end
                          end

                          instance = ChildClass.new
                          instance.some_method
                          instance.child_method
                          instance.another_method)";

  Object result = m.module_eval(code);
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(subclass_override_initializer)
{
  Module m = define_module("Testing");
  define_class_under<BaseClass>(m, "BaseClass").
    define_constructor(Constructor<BaseClass>()).
    define_method("some_method", &BaseClass::some_method);

  std::string code = R"(class ChildClass < BaseClass
                          def initialize
                            # Note NO super call so class in incorrectly initialized
                          end
                        end

                        instance = ChildClass.new
                        instance.some_method)";

  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.module_eval(code),
    ASSERT_EQUAL("Wrapped C++ object is nil. Did you override Testing::ChildClass#initialize and forget to call super?", ex.what())
  );
}

namespace {
  float with_reference_defaults_x;
  std::string with_reference_defaults_str;

  class DefaultArgsRefs
  {
  public:
    void with_reference_defaults(float x, std::string const& str = std::string("testing"))
    {
      with_reference_defaults_x = x;
      with_reference_defaults_str = str;
    }
  };
}

TESTCASE(define_method_works_with_reference_const_default_values)
{
  Class c = define_class<DefaultArgsRefs>("DefaultArgsRefs")
    .define_constructor(Constructor<DefaultArgsRefs>())
    .define_method("bar",
      &DefaultArgsRefs::with_reference_defaults,
      Arg("x"), Arg("str") = std::string("testing"));

  Object o = c.call("new");
  o.call("bar", 3);

  ASSERT_EQUAL(3, with_reference_defaults_x);
  ASSERT_EQUAL("testing", with_reference_defaults_str);
}

namespace
{
  class RefTest
  {
  public:
    RefTest() {}

    static std::string& getReference()
    {
      static std::string foo = "foo";
      return foo;
    }
  };
}

TESTCASE(define_singleton_method_returning_reference)
{
  Class c = define_class<RefTest>("RefTest")
    .define_constructor(Constructor<RefTest>())
    .define_singleton_function("get_reference", &RefTest::getReference);

  Module m(anonymous_module());

  Object result = m.module_eval("RefTest.get_reference");
  ASSERT_EQUAL(result, String("foo"));
}

namespace
{
  struct MyStruct
  {
    MyStruct* set(MyStruct* ptr)
    {
      assert(ptr == nullptr);
      return ptr;
    }

    MyStruct* get()
    {
      return nullptr;
    }
  };
}

TESTCASE(null_ptrs)
{
  Class c = define_class<MyStruct>("MyStruct")
    .define_constructor(Constructor<MyStruct>())
    .define_method("get", &MyStruct::get)
    .define_method("set", &MyStruct::set);

  Object o = c.call("new");

  Object result = o.call("get");
  ASSERT_EQUAL(Qnil, result.value());

  result = o.call("set", nullptr);
  ASSERT_EQUAL(Qnil, result.value());
}

namespace
{
  class SomeClass
  {
  };

  void undefinedArg(SomeClass& someClass)
  {
  }

  SomeClass undefinedReturn()
  {
    return SomeClass();
  }
}

TESTCASE(not_defined)
{
#ifdef _MSC_VER
  const char* message = "Type is not defined with Rice: class `anonymous namespace'::SomeClass";
#else
  const char* message = "Type is not defined with Rice: (anonymous namespace)::SomeClass";
#endif
    
    ASSERT_EXCEPTION_CHECK(
    std::invalid_argument,
    define_global_function("undefined_arg", &undefinedArg),
    ASSERT_EQUAL(message, ex.what())
  );

  ASSERT_EXCEPTION_CHECK(
    std::invalid_argument,
    define_global_function("undefined_return", &undefinedReturn),
    ASSERT_EQUAL(message, ex.what())
  );
}

namespace
{
  class Container
  {
  public:
    size_t capacity()
    {
      return this->capacity_;
    }

    void capacity(size_t value)
    {
      this->capacity_ = value;
    }

  private:
    size_t capacity_;
  };
}

TESTCASE(OverloadsWithTemplateParameter)
{
  Class c = define_class<Container>("Container")
    .define_constructor(Constructor<Container>())
    .define_method<size_t(Container::*)()>("capacity", &Container::capacity)
    .define_method<void(Container::*)(size_t)>("capacity=", &Container::capacity);

  
  Module m = define_module("Testing");

  std::string code = R"(container = Container.new
                        container.capacity = 5
                        container.capacity)";

  Object result = m.module_eval(code);
  ASSERT_EQUAL(5, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(OverloadsWithUsing)
{
  using Getter_T = size_t(Container::*)();
  using Setter_T = void(Container::*)(size_t);

  Class c = define_class<Container>("Container")
    .define_constructor(Constructor<Container>())
    .define_method("capacity", (Getter_T)&Container::capacity)
    .define_method("capacity=", (Setter_T)&Container::capacity);

  Module m = define_module("Testing");

  std::string code = R"(container = Container.new
                        container.capacity = 6
                        container.capacity)";

  Object result = m.module_eval(code);
  ASSERT_EQUAL(6, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(OverloadsWithTypedef)
{
  typedef size_t(Container::* Getter_T)();
  typedef void (Container::* Setter_T)(size_t);

  Class c = define_class<Container>("Container")
    .define_constructor(Constructor<Container>())
    .define_method("capacity", (Getter_T)&Container::capacity)
    .define_method("capacity=", (Setter_T)&Container::capacity);

  Module m = define_module("Testing");

  std::string code = R"(container = Container.new
                        container.capacity = 7
                        container.capacity)";

  Object result = m.module_eval(code);
  ASSERT_EQUAL(7, detail::From_Ruby<int>().convert(result.value()));
}