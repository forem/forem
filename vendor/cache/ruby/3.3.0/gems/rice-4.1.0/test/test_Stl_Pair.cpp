#include <utility>

#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(Pair);

SETUP(Pair)
{
  embed_ruby();
}

TESTCASE(CreatePair)
{
  Module m = define_module("Testing");

  Class c = define_pair<std::pair<int32_t, std::optional<std::string>>>("IntStringPair");

  Object pair = c.call("new", 0, nullptr);

  Object result = pair.call("first");
  ASSERT_EQUAL(0, detail::From_Ruby<int32_t>().convert(result));

  result = pair.call("second");
  ASSERT_EQUAL(Qnil, result.value());

  result = pair.call("first=", 77);
  ASSERT_EQUAL(77, detail::From_Ruby<int32_t>().convert(result));

  result = pair.call("first");
  ASSERT_EQUAL(77, detail::From_Ruby<int32_t>().convert(result));

  result = pair.call("second=", "A second value");
  ASSERT_EQUAL("A second value", detail::From_Ruby<std::string>().convert(result));

  result = pair.call("second");
  ASSERT_EQUAL("A second value", detail::From_Ruby<std::string>().convert(result));
}

TESTCASE(CreatePairConst)
{
  Module m = define_module("Testing");

  Class c = define_pair<std::pair<const std::string, const std::string>>("ConstStringPair");
  Object pair = c.call("new", "pair1", "pair2");

  Object result = pair.call("first");
  ASSERT_EQUAL("pair1", detail::From_Ruby<std::string>().convert(result));

  result = pair.call("second");
  ASSERT_EQUAL("pair2", detail::From_Ruby<std::string>().convert(result));

  ASSERT_EXCEPTION_CHECK(
    Exception,
    pair.call("first=", "A second value"),
    ASSERT_EQUAL("Cannot set pair.first since it is a constant", ex.what())
  );

  ASSERT_EXCEPTION_CHECK(
    Exception,
    pair.call("second=", "A second value"),
    ASSERT_EQUAL("Cannot set pair.second since it is a constant", ex.what())
  );
}

namespace
{
  class SomeClass
  {
  public:
    std::pair<std::string, double> pair()
    {
      return pair_;
    }

    std::pair<std::string, double> setPair(std::pair<std::string, double> value)
    {
      pair_ = value;
      return pair_;
    }

    std::pair<std::string, double> pair_{ "first value", 2.0 };
  };
}

// This test passes everywhere except for Ruby 2.7 on Windows
// and I don't know why. Throws a "bad any_cast" from MethodData::data
TESTCASE(AutoRegister)
{
  Module m = define_module("Testing");

  Class c = define_class<SomeClass>("SomeClass").
    define_constructor(Constructor<SomeClass>()).
    define_method("pair", &SomeClass::pair).
    define_method("pair=", &SomeClass::setPair);

  Object someClass = c.call("new");

  Object pair = someClass.call("pair");
  String name = pair.class_name();
  ASSERT_EQUAL("Rice::Std::Pair__basic_string__char_char_traits__char___allocator__char_____double__", detail::From_Ruby<std::string>().convert(name));

  Class pairKlass1 = pair.class_of();
  Class pairKlass2 = Data_Type<std::pair<std::string, double>>::klass();
  ASSERT_EQUAL(pairKlass1, pairKlass2);

  Object result = pair.call("first");
  ASSERT_EQUAL("first value", detail::From_Ruby<std::string>().convert(result));

  result = pair.call("second");
  ASSERT_EQUAL(2.0, detail::From_Ruby<float>().convert(result));

  Object newPair = pairKlass1.call("new", "New value", 3.2);

  pair = someClass.call("pair=", newPair);

  result = newPair.call("first");
  ASSERT_EQUAL("New value", detail::From_Ruby<std::string>().convert(result));

  result = newPair.call("second");
  ASSERT_EQUAL(3.2, detail::From_Ruby<double>().convert(result));

  // Now register the pair again
  define_pair<std::pair<std::string, double>>("SomePair");
  std::string code = R"(pair = SomePair.new('string', 2.0))";
  result = m.module_eval(code);
  ASSERT(result.is_instance_of(pair.class_of()));

  // And again in the module
  define_pair_under<std::pair<std::string, double>>(m, "SomePair2");
  code = R"(pair = Testing::SomePair2.new('string', 3.0))";
  result = m.module_eval(code);
  ASSERT(result.is_instance_of(pair.class_of()));
}

namespace
{
  struct SomeStruct
  {
    int32_t value = 5;
  };
}

TESTCASE(ReferenceReturned)
{
  Class structKlass = define_class<SomeStruct>("SomeStruct").
    define_constructor(Constructor<SomeStruct>()).
    define_attr("value", &SomeStruct::value);

  define_pair<std::pair<char, SomeStruct>>("CharSomeStructPair");

  std::pair<char, SomeStruct> aPair;
  aPair.first = 'a';

  Data_Object<std::pair<char, SomeStruct>> rubyPair(&aPair);

  Object result = rubyPair.call("first");
  ASSERT_EQUAL('a', detail::From_Ruby<char>().convert(result));

  result = rubyPair.call("first=", 'b');
  ASSERT_EQUAL('b', aPair.first);

  result = rubyPair.call("first");
  ASSERT_EQUAL('b', detail::From_Ruby<char>().convert(result));

  Object rubyStruct = rubyPair.call("second");
  result = rubyStruct.call("value");
  ASSERT_EQUAL(5, detail::From_Ruby<int32_t>().convert(result));

  rubyStruct.call("value=", 8);
  ASSERT_EQUAL(8, aPair.second.value);

  rubyStruct = rubyPair.call("second");
  result = rubyStruct.call("value");
  ASSERT_EQUAL(8, detail::From_Ruby<int32_t>().convert(result));
}
