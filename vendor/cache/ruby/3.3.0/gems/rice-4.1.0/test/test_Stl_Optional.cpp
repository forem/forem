#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include <optional>

using namespace Rice;

TESTSUITE(Optional);

namespace
{
  class MyClass
  {
  public:
    std::optional<std::string> optionalReturn(bool flag)
    {
      if (flag)
      {
        return std::string("Here is a value");
      }
      else
      {
        return std::nullopt;
      }
    }

    int optionalArgument(std::optional<int32_t> data)
    {
      return data ? data.value() : 7;
    }

    std::optional<double> optional_ = std::nullopt;
  };
}

Class makeOptionalClass()
{
  return define_class<MyClass>("MyClass").
    define_constructor(Constructor<MyClass>()).
    define_method("optional_return", &MyClass::optionalReturn).
    define_method("optional_argument", &MyClass::optionalArgument).
    define_attr("optional_attr", &MyClass::optional_);
}

SETUP(Optional)
{
  embed_ruby();
  makeOptionalClass();
}

TESTCASE(OptionalReturn)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("optional_return", true);
  ASSERT_EQUAL("Here is a value", detail::From_Ruby<std::string>().convert(result));

  result = myClass.call("optional_return", false);
  ASSERT_EQUAL(Qnil, result.value());
}

TESTCASE(OptionalArgument)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("optional_argument", 77);
  ASSERT_EQUAL(77, detail::From_Ruby<int32_t>().convert(result));

  result = myClass.call("optional_argument", std::nullopt);
  ASSERT_EQUAL(7, detail::From_Ruby<int32_t>().convert(result));
}

TESTCASE(OptionalAttribute)
{
  Module m = define_module("Testing");
  Object myClass = m.module_eval("MyClass.new");

  Object result = myClass.call("optional_attr");
  ASSERT_EQUAL(Qnil, result.value());

  result = myClass.call("optional_attr=", 77.7);
  ASSERT_EQUAL(77.7, detail::From_Ruby<double>().convert(result));

  result = myClass.call("optional_attr=", std::nullopt);
  ASSERT_EQUAL(Qnil, result.value());
}
