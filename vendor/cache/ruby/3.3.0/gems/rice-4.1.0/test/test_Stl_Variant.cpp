#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include <variant>

using namespace Rice;

TESTSUITE(Variant);

namespace
{
  using Intrinsic_Variant_T = std::variant<std::string, double, bool, int>;

  inline std::ostream& operator<<(std::ostream& stream, Intrinsic_Variant_T const& variant)
  {
    stream << "Variant(" << "index: " << variant.index() << ")";
    return stream;
  }

  class MyClass
  {
  public:
    Intrinsic_Variant_T variantString()
    {
      // Need to tell compiler this is std::string and not a const char[8]. Because that
      // becomes const char* which sets the boolean field to true. Oops. https://stackoverflow.com/a/44086312
      Intrinsic_Variant_T result { std::string("a string") };
      return result;
    }

    Intrinsic_Variant_T variantDouble()
    {
      Intrinsic_Variant_T result { 3.3 };
      return result;
    }

    Intrinsic_Variant_T variantBoolTrue()
    {
      Intrinsic_Variant_T result { true };
      return result;
    }

    Intrinsic_Variant_T variantBoolFalse()
    {
      Intrinsic_Variant_T result{ false };
      return result;
    }

    Intrinsic_Variant_T variantInt()
    {
      Intrinsic_Variant_T result { 5 };
      return result;
    }

    Intrinsic_Variant_T variantRoundtrip(Intrinsic_Variant_T variant)
    {
      return variant;
    }

    Intrinsic_Variant_T variantRoundtripReference(Intrinsic_Variant_T variant)
    {
      return variant;
    }

    Intrinsic_Variant_T variant_ = std::string("Initial value");
  };
}

void makeIntrinsicVariant()
{
  define_class<MyClass>("MyClass").
    define_constructor(Constructor<MyClass>()).
    define_method("variant_string", &MyClass::variantString).
    define_method("variant_double", &MyClass::variantDouble).
    define_method("variant_bool_true", &MyClass::variantBoolTrue).
    define_method("variant_bool_false", &MyClass::variantBoolFalse).
    define_method("variant_int", &MyClass::variantInt).
    define_method("roundtrip", &MyClass::variantRoundtrip).
    define_attr("variant_attr", &MyClass::variant_);
}

TESTCASE(IntrinsicReturns)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("variant_string");
  ASSERT_EQUAL("a string", detail::From_Ruby<std::string>().convert(result));
  
  result = myClass.call("variant_double");
  ASSERT_EQUAL(3.3, detail::From_Ruby<double>().convert(result));

  result = myClass.call("variant_bool_true");
  ASSERT(detail::From_Ruby<bool>().convert(result));

  result = myClass.call("variant_bool_false");
  ASSERT(!detail::From_Ruby<bool>().convert(result));

  result = myClass.call("variant_int");
  ASSERT_EQUAL(5, detail::From_Ruby<int>().convert(result));
}

TESTCASE(IntrinsicRoundtrip)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  std::string code = R"(my_class = MyClass.new
                        my_class.roundtrip("roundtrip string"))";
  Object result = m.module_eval(code);
  ASSERT_EQUAL("roundtrip string", detail::From_Ruby<std::string>().convert(result));

  code = R"(my_class = MyClass.new
            my_class.roundtrip(44.4))";
  result = m.module_eval(code);
  ASSERT_EQUAL(44.4, detail::From_Ruby<double>().convert(result));

  code = R"(my_class = MyClass.new
            my_class.roundtrip(true))";
  result = m.module_eval(code);
  ASSERT(detail::From_Ruby<bool>().convert(result));

  code = R"(my_class = MyClass.new
            my_class.roundtrip(false))";
  result = m.module_eval(code);
  ASSERT(!detail::From_Ruby<bool>().convert(result));

  code = R"(my_class = MyClass.new
            my_class.roundtrip(45))";
  result = m.module_eval(code);
  ASSERT_EQUAL(45, detail::From_Ruby<int>().convert(result));
}

TESTCASE(VariantAttribute)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("variant_attr");
  ASSERT_EQUAL("Initial value", detail::From_Ruby<std::string>().convert(result));

  result = myClass.call("variant_attr=", "Second value");
  ASSERT_EQUAL("Second value", detail::From_Ruby<std::string>().convert(result));
  result = myClass.call("variant_attr");
  ASSERT_EQUAL("Second value", detail::From_Ruby<std::string>().convert(result));

  result = myClass.call("variant_attr=", 77.7);
  ASSERT_EQUAL(77.7, detail::From_Ruby<double>().convert(result));
  result = myClass.call("variant_attr");
  ASSERT_EQUAL(77.7, detail::From_Ruby<double>().convert(result));
  
  result = myClass.call("variant_attr=", true);
  ASSERT(detail::From_Ruby<bool>().convert(result));
  result = myClass.call("variant_attr");
  ASSERT(detail::From_Ruby<bool>().convert(result));

  result = myClass.call("variant_attr=", false);
  ASSERT(!detail::From_Ruby<bool>().convert(result));
  result = myClass.call("variant_attr");
  ASSERT(!detail::From_Ruby<bool>().convert(result));

  result = myClass.call("variant_attr=", 78);
  ASSERT_EQUAL(78, detail::From_Ruby<int>().convert(result));
  result = myClass.call("variant_attr");
  ASSERT_EQUAL(78, detail::From_Ruby<int>().convert(result));
}

namespace
{
  class MyClass1
  {
  public:
    MyClass1()
    {
      int a = 1;
    }

    std::string sayHello()
    {
      return "Hi from MyClass1";
    }
  };

  class MyClass2
  {
  public:
    MyClass2()
    {
      int a = 2;
    }

    std::string sayHello()
    {
      return "Hi from MyClass2";
    }
  };

  using Class_Variant_T = std::variant<std::monostate, MyClass1, MyClass2>;

  Class_Variant_T variantClass(bool myClass1)
  {
    if (myClass1)
    {
      return MyClass1();
    }
    else
    {
      return MyClass2();
    }
  }

  Class_Variant_T roundTripVariantClass(Class_Variant_T variant)
  {
    return variant;
  }

  Class_Variant_T& roundTripVariantClassRef(Class_Variant_T& variant)
  {
    return variant;
  }
}

void makeClassVariant()
{
  define_class<MyClass1>("MyClass1").
    define_constructor(Constructor<MyClass1>()).
    define_method("say_hello", &MyClass1::sayHello);

  define_class<MyClass2>("MyClass2").
    define_constructor(Constructor<MyClass2>()).
    define_method("say_hello", &MyClass2::sayHello);

  define_global_function("variant_class", &variantClass);
  define_global_function("roundtrip_variant_class", &roundTripVariantClass);
  define_global_function("roundtrip_variant_class_ref", &roundTripVariantClassRef);
}

SETUP(Variant)
{
  embed_ruby();
  makeIntrinsicVariant();
  makeClassVariant();
}

TESTCASE(ClassReturns)
{
  Module m = define_module("Testing");

  Data_Object<MyClass1> myclass1 = m.module_eval("variant_class(true)");
  String hello = myclass1.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass1", detail::From_Ruby<std::string>().convert(hello));

  Data_Object<MyClass2> myclass2 = m.module_eval("variant_class(false)");
  hello = myclass2.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass2", detail::From_Ruby<std::string>().convert(hello));
}

TESTCASE(ClassRoundtrip)
{
  Module m = define_module("Testing");

  Object instance = m.module_eval("MyClass1.new");
  Object instance2 = m.call("roundtrip_variant_class", instance);
  String hello = instance2.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass1", detail::From_Ruby<std::string>().convert(hello));

  instance = m.module_eval("MyClass2.new");
  instance2 = m.call("roundtrip_variant_class", instance);
  hello = instance2.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass2", detail::From_Ruby<std::string>().convert(hello));
}

/* This test case runs successfully on MSVC but not g++. Having stepped through the code with
  GDB, this sure seems due to a bug with g++. The issue is this variable in created operator():

        Arg_Ts nativeValues = this->getNativeValues(rubyValues, indices);

 And is then passed to invokeNativeFunction as a const Arg_Ts& nativeArgs where Arg_Ts& is
 std::tuple with one element, a reference to a variant. So it doesn't change and the address
 of the variable doesn't change. But for some reason g++ resets the
 the std::variant index to 0 thus breaking the test. Maybe something to do with storing
 a refernence to a variant in a tuple? */

#ifdef _MSC_VER
TESTCASE(ClassRoundtripRef)
{
  Module m = define_module("Testing");

  Object instance = m.module_eval("MyClass1.new");
  Object instance2 = m.call("roundtrip_variant_class_ref", instance);
  String hello = instance2.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass1", detail::From_Ruby<std::string>().convert(hello));

  instance = m.module_eval("MyClass2.new");
  instance2 = m.call("roundtrip_variant_class_ref", instance);
  hello = instance2.call("say_hello");
  ASSERT_EQUAL("Hi from MyClass2", detail::From_Ruby<std::string>().convert(hello));
}
#endif