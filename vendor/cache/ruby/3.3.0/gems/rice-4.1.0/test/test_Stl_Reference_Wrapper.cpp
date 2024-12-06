#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include <functional>

using namespace Rice;

TESTSUITE(ReferenceWrapper);

namespace
{
  class MyClass
  {
  public:
    int reference_wrapper_argument(std::reference_wrapper<int32_t> ref)
    {
      return ref.get();
    }

    std::reference_wrapper<std::string> reference_wrapper_return()
    {
      return reference_wrapper_;
    }

    std::string say_hello()
    {
      return "My ref wrapper class";
    }

    std::string string_ = "A ref wrapped string";
    std::reference_wrapper<std::string> reference_wrapper_ = std::ref(string_);
  };

  std::reference_wrapper<MyClass> roundtrip_class(std::reference_wrapper<MyClass> instance)
  {
    return instance;
  }

  std::variant<std::reference_wrapper<MyClass>> roundtrip_class_in_variant(std::variant<std::reference_wrapper<MyClass>> instance)
  {
    return instance;
  }
}

void makeReferenceWrapperClass()
{
  define_class<MyClass>("MyClass").
    define_constructor(Constructor<MyClass>()).
    define_method("reference_wrapper_argument", &MyClass::reference_wrapper_argument).
    define_method("reference_wrapper_return", &MyClass::reference_wrapper_return);

  define_global_function("roundtrip_class", &roundtrip_class);
  define_global_function("roundtrip_class_in_variant", &roundtrip_class_in_variant);
}

SETUP(ReferenceWrapper)
{
  embed_ruby();
  makeReferenceWrapperClass();
}

TESTCASE(Return)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("reference_wrapper_return");
  ASSERT_EQUAL("A ref wrapped string", detail::From_Ruby<std::string>().convert(result));
}

TESTCASE(Argument)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("reference_wrapper_argument", 77);
  ASSERT_EQUAL(77, detail::From_Ruby<int32_t>().convert(result));
}

TESTCASE(RoundTrip)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("roundtrip_class", myClass);
  Data_Object<MyClass> finish(result);

  ASSERT_EQUAL(Data_Object<MyClass>::from_ruby(myClass), Data_Object<MyClass>::from_ruby(result));
}

TESTCASE(RoundTripInVariant)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("roundtrip_class_in_variant", myClass);
  Data_Object<MyClass> finish(result);

  ASSERT_EQUAL(Data_Object<MyClass>::from_ruby(myClass), Data_Object<MyClass>::from_ruby(result));
}
