#include <complex>
#include <memory>

#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(UnorderedMap);

SETUP(UnorderedMap)
{
  embed_ruby();
}

namespace
{

  class MyClass
  {
  public:
    std::unordered_map<std::string, std::string> stringUnorderedMap()
    {
      std::unordered_map<std::string, std::string> result{ {"One", "1"}, {"Two", "2"}, {"Three", "3"} };
      return result;
    }
  };
}

Class makeUnorderedUnorderedMapClass()
{
  Class c = define_class<MyClass>("MyClass").
    define_constructor(Constructor<MyClass>()).
    define_method("stringUnorderedMap", &MyClass::stringUnorderedMap);

  return c;
}

TESTCASE(StringUnorderedMap)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::string>>("StringUnorderedMap");

  Object unordered_map = m.module_eval("$unordered_map = StringUnorderedMap.new");
  Object result = unordered_map.call("size");
  ASSERT_EQUAL(0, detail::From_Ruby<int32_t>().convert(result));

  m.module_eval("$unordered_map['a_key'] = 'a_value'");
  result = unordered_map.call("size");
  ASSERT_EQUAL(1, detail::From_Ruby<int32_t>().convert(result));

  m.module_eval("$unordered_map.clear");
  result = unordered_map.call("size");
  ASSERT_EQUAL(0, detail::From_Ruby<int32_t>().convert(result));
}

TESTCASE(WrongType)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::string>>("StringUnorderedMap");
  Object unordered_map = m.module_eval("$unordered_map = StringUnorderedMap.new");

  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.module_eval("$unordered_map[1] = 'abc'"),
    ASSERT_EQUAL("wrong argument type Integer (expected String)", ex.what()));

  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.module_eval("$unordered_map['abc'] = true"),
    ASSERT_EQUAL("wrong argument type true (expected String)", ex.what()));
}

TESTCASE(Empty)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::int32_t>>("IntUnorderedMap");
  Object unordered_map = c.call("new");

  Object result = unordered_map.call("size");
  ASSERT_EQUAL(0, detail::From_Ruby<int32_t>().convert(result));

  result = unordered_map.call("empty?");
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(Include)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::int32_t>>("IntUnorderedMap");
  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", 1);
  unordered_map.call("[]=", "two", 2);

  Object result = unordered_map.call("include?", "two");
  ASSERT_EQUAL(Qtrue, result.value());

  result = unordered_map.call("include?", "three");
  ASSERT_EQUAL(Qfalse, result.value());

  result = unordered_map.call("[]", "three");
  ASSERT_EQUAL(Qnil, result.value());
}

TESTCASE(Value)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::int32_t>>("IntUnorderedMap");
  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", 1);
  unordered_map.call("[]=", "two", 2);

  Object result = unordered_map.call("value?", 2);
  ASSERT_EQUAL(Qtrue, result.value());

  result = unordered_map.call("value?", 4);
  ASSERT_EQUAL(Qfalse, result.value());
}

TESTCASE(ToString)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::int32_t>>("IntUnorderedMap");
  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", 1);
  unordered_map.call("[]=", "two", 2);

  Object result = unordered_map.call("to_s");
  ASSERT_EQUAL("{two => 2, one => 1}", detail::From_Ruby<std::string>().convert(result));

  unordered_map.call("clear");

  result = unordered_map.call("to_s");
  ASSERT_EQUAL("{}", detail::From_Ruby<std::string>().convert(result));
}

TESTCASE(Update)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, std::string>>("StringUnorderedMap");
  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", "original 1");
  unordered_map.call("[]=", "two", "original 2");

  Object result = unordered_map.call("size");
  ASSERT_EQUAL(2, detail::From_Ruby<int32_t>().convert(result));

  result = unordered_map.call("[]=", "two", "new 2");
  ASSERT_EQUAL("new 2", detail::From_Ruby<std::string>().convert(result));

  result = unordered_map.call("size");
  ASSERT_EQUAL(2, detail::From_Ruby<int32_t>().convert(result));

  result = unordered_map.call("[]", "two");
  ASSERT_EQUAL("new 2", detail::From_Ruby<std::string>().convert(result));
}

TESTCASE(Modify)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, int64_t>>("Int64UnorderedMap");
  Object unordered_map = c.call("new");

  Object result = unordered_map.call("[]=", "one", 3232323232);

  result = unordered_map.call("size");
  ASSERT_EQUAL(1, detail::From_Ruby<int32_t>().convert(result));

  result = unordered_map.call("delete", "one");
  ASSERT_EQUAL(3232323232, detail::From_Ruby<int64_t>().convert(result));

  result = unordered_map.call("size");
  ASSERT_EQUAL(0, detail::From_Ruby<int32_t>().convert(result));
}

TESTCASE(keysAndValues)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, int32_t>>("Int32UnorderedMap");
  Object unordered_map = c.call("new");

  unordered_map.call("[]=", "one", 1);
  unordered_map.call("[]=", "two", 2);
  unordered_map.call("[]=", "three", 3);

  // Keys returns a std::vector
  Data_Object<std::vector<std::string>> keys = unordered_map.call("keys");
  //std::vector<std::string> expected_keys{ {"one", "three", "two"} };
  ASSERT_EQUAL(3u, keys->size());
  //ASSERT_EQUAL(expected_keys[0], keys->operator[](0));
  //ASSERT_EQUAL(expected_keys[1], keys->operator[](1));
  //ASSERT_EQUAL(expected_keys[2], keys->operator[](2));

  // Keys returns a std::vector
  Data_Object<std::vector<std::int32_t>> values = unordered_map.call("values");
  //std::vector<std::int32_t> expected_values{ {1, 3, 2} };
  ASSERT_EQUAL(3u, values->size());
  //ASSERT_EQUAL(expected_values[0], values->operator[](0));
  //ASSERT_EQUAL(expected_values[1], values->operator[](1));
  //ASSERT_EQUAL(expected_values[2], values->operator[](2));
}

TESTCASE(Copy)
{
  Module m = define_module("Testing");

  Class c = define_unordered_map<std::unordered_map<std::string, double>>("DoubleUnorderedMap");
  Object object = c.call("new");

  object.call("[]=", "one", 11.1);
  object.call("[]=", "two", 22.2);
  std::unordered_map<std::string, double>& unordered_map = detail::From_Ruby<std::unordered_map<std::string, double>&>().convert(object);

  Object result = object.call("copy");
  std::unordered_map<std::string, double>& unordered_mapCopy = detail::From_Ruby<std::unordered_map<std::string, double>&>().convert(result);

  ASSERT_EQUAL(unordered_map.size(), unordered_mapCopy.size());
  ASSERT_EQUAL(unordered_map["one"], unordered_mapCopy["one"]);
  ASSERT_EQUAL(unordered_map["two"], unordered_mapCopy["two"]);

  unordered_mapCopy["three"] = 33.3;
  ASSERT_NOT_EQUAL(unordered_map.size(), unordered_mapCopy.size());
}

TESTCASE(Iterate)
{
  Module m = define_module("Testing");
  Class c = define_unordered_map<std::unordered_map<std::string, int>>("IntUnorderedMap");

  std::string code = R"(unordered_map = IntUnorderedMap.new
                        unordered_map["five"] = 5
                        unordered_map["six"] = 6
                        unordered_map["seven"] = 7

                        result = Hash.new
                        unordered_map.each do |pair|
                                    result[pair.first] = 2 * pair.second
                                  end
                        result)";

  Hash result = m.module_eval(code);
  ASSERT_EQUAL(3u, result.size());

  std::string result_string = result.to_s().str();
  ASSERT_EQUAL(R"({"seven"=>14, "six"=>12, "five"=>10})", result_string);
}

TESTCASE(ToEnum)
{
  Module m = define_module("Testing");
  Class c = define_unordered_map<std::unordered_map<std::string, int>>("IntUnorderedMap");

  std::string code = R"(unordered_map = IntUnorderedMap.new
                        unordered_map["five"] = 5
                        unordered_map["six"] = 6
                        unordered_map["seven"] = 7

                        result = Hash.new
                        unordered_map.each.each do |pair|
                                    result[pair.first] = 2 * pair.second
                                  end
                        result)";

  Hash result = m.module_eval(code);
  ASSERT_EQUAL(3u, result.size());

  std::string result_string = result.to_s().str();
  ASSERT_EQUAL(R"({"seven"=>14, "six"=>12, "five"=>10})", result_string);
}

TESTCASE(ToEnumSize)
{
  Module m = define_module("TestingModule");
  Class c = define_unordered_map<std::unordered_map<std::string, int>>("IntUnorderedMap");

  std::string code = R"(map = IntUnorderedMap.new
                        map["five"] = 5
                        map["six"] = 6
                        map["seven"] = 7
                        map["eight"] = 7
                        map)";

  Object map = m.module_eval(code);
  Object enumerable = map.call("each");
  Object result = enumerable.call("size");

  ASSERT_EQUAL(4, detail::From_Ruby<int>().convert(result));
}


namespace
{
  class NotComparable
  {
  public:
    NotComparable(uint32_t value) : value_(value)
    {
    };

    NotComparable() = default;

    uint32_t value_;
  };
}

TESTCASE(NotComparable)
{
  define_class<NotComparable>("NotComparable").
    define_constructor(Constructor<NotComparable, uint32_t>());

  Class c = define_unordered_map<std::unordered_map<std::string, NotComparable>>("NotComparableUnorderedMap");

  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", NotComparable(1));
  unordered_map.call("[]=", "two", NotComparable(2));
  unordered_map.call("[]=", "three", NotComparable(3));

  Object result = unordered_map.call("include?", "two");
  ASSERT_EQUAL(Qtrue, result.value());

  result = unordered_map.call("value?", NotComparable(3));
  ASSERT_EQUAL(Qfalse, result.value());
}

TESTCASE(NotPrintable)
{
  define_class<NotComparable>("NotComparable").
    define_constructor(Constructor<NotComparable, uint32_t>());

  Class c = define_unordered_map<std::unordered_map<std::string, NotComparable>>("NotComparableUnorderedMap");

  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", NotComparable(1));
  unordered_map.call("[]=", "two", NotComparable(2));
  unordered_map.call("[]=", "three", NotComparable(3));

  Object result = unordered_map.call("to_s");
  ASSERT_EQUAL("[Not printable]", detail::From_Ruby<std::string>().convert(result));
}

namespace
{
  class Comparable
  {
  public:
    Comparable() = default;
    Comparable(uint32_t value) : value_(value)
    {
    };

    bool operator==(const Comparable& other)
    {
      return this->value_ == other.value_;
    }

    uint32_t value_;
  };

  inline std::ostream& operator<<(std::ostream& stream, Comparable const& comparable)
  {
    stream << "Comparable(" << std::to_string(comparable.value_) << ")";
    return stream;
  }
}

TESTCASE(Comparable)
{
  define_class<Comparable>("IsComparable").
    define_constructor(Constructor<Comparable, uint32_t>());

  Class c = define_unordered_map<std::unordered_map<std::string, Comparable>>("ComparableUnorderedMap");

  Object unordered_map = c.call("new");
  
  unordered_map.call("[]=", "one", Comparable(1));
  unordered_map.call("[]=", "two", Comparable(2));
  unordered_map.call("[]=", "three", Comparable(3));

  Object result = unordered_map.call("value?", Comparable(2));
  ASSERT_EQUAL(Qtrue, result.value());
}

TESTCASE(Printable)
{
  define_class<Comparable>("IsComparable").
    define_constructor(Constructor<Comparable, uint32_t>());

  Class c = define_unordered_map<std::unordered_map<std::string, Comparable>>("ComparableUnorderedMap");

  Object unordered_map = c.call("new");
  unordered_map.call("[]=", "one", Comparable(1));
  unordered_map.call("[]=", "two", Comparable(2));
  unordered_map.call("[]=", "three", Comparable(3));

  Object result = unordered_map.call("to_s");
  ASSERT_EQUAL("{three => Comparable(3), two => Comparable(2), one => Comparable(1)}", detail::From_Ruby<std::string>().convert(result));
}

namespace
{
  std::unordered_map<std::string, std::complex<double>> returnComplexUnorderedMap()
  {
    std::complex<double> complex1(1, 1);
    std::complex<double> complex2(2, 2);
    std::complex<double> complex3(3, 3);

    std::unordered_map<std::string, std::complex<double>> result;
    result["one"] = complex1;
    result["two"] = complex2;
    result["three"] = complex3;
    return result;
  }

  std::unordered_map<std::string, std::complex<double>> passComplexUnorderedMap(std::unordered_map<std::string, std::complex<double>>& complexes)
  {
    return complexes;
  }
}

TESTCASE(AutoRegisterReturn)
{
  define_global_function("return_complex_unordered_map", &returnComplexUnorderedMap);

  Module m = define_module("Testing");
  Object unordered_map = m.module_eval("return_complex_unordered_map");
  ASSERT_EQUAL("Rice::Std::Unordered_map__basic_string__char_char_traits__char___allocator__char_____complex__double___hash__basic_string__char_char_traits__char___allocator__char_______equal_to__basic_string__char_char_traits__char___allocator__char_______allocator__pair__basic_string__char_char_traits__char___allocator__char____Const_complex__double________",
               unordered_map.class_name().str());

  std::string code = R"(unordered_map = return_complex_unordered_map
                        complex = unordered_map['three']
                        complex == Complex(3, 3))";

  Object result = m.module_eval(code);
  ASSERT_EQUAL(Qtrue, result.value());

  // Now register the unordered_map again
  define_unordered_map<std::unordered_map<std::string, std::complex<double>>>("ComplexUnorderedMap");
  code = R"(unordered_map = ComplexUnorderedMap.new)";
  result = m.module_eval(code);
  ASSERT(result.is_instance_of(unordered_map.class_of()));

  // And again in the module
  define_unordered_map_under<std::unordered_map<std::string, std::complex<double>>>(m, "ComplexUnorderedMap2");
  code = R"(unordered_map = Testing::ComplexUnorderedMap2.new)";
  result = m.module_eval(code);
  ASSERT(result.is_instance_of(unordered_map.class_of()));
}

TESTCASE(AutoRegisterParameter)
{
  define_global_function("pass_complex_unordered_map", &passComplexUnorderedMap);

  std::string code = R"(unordered_map = Rice::Std::Unordered_map__basic_string__char_char_traits__char___allocator__char_____complex__double___hash__basic_string__char_char_traits__char___allocator__char_______equal_to__basic_string__char_char_traits__char___allocator__char_______allocator__pair__basic_string__char_char_traits__char___allocator__char____Const_complex__double________.new
                        unordered_map["four"] = Complex(4.0, 4.0)
                        unordered_map["five"] = Complex(5.0, 5.0)
                        pass_complex_unordered_map(unordered_map))";

  Module m = define_module("Testing");
  Object unordered_map = m.module_eval(code);

  Object result = unordered_map.call("size");
  ASSERT_EQUAL("Rice::Std::Unordered_map__basic_string__char_char_traits__char___allocator__char_____complex__double___hash__basic_string__char_char_traits__char___allocator__char_______equal_to__basic_string__char_char_traits__char___allocator__char_______allocator__pair__basic_string__char_char_traits__char___allocator__char____Const_complex__double________",
               unordered_map.class_name().str());
  ASSERT_EQUAL(2, detail::From_Ruby<int32_t>().convert(result));

  std::unordered_map<std::string, std::complex<double>> complexes = detail::From_Ruby<std::unordered_map<std::string, std::complex<double>>>().convert(unordered_map);
  ASSERT_EQUAL(complexes["four"], std::complex<double>(4, 4));
  ASSERT_EQUAL(complexes["five"], std::complex<double>(5, 5));
}

namespace
{
  std::unordered_map<std::string, std::string> defaultUnorderedMap(std::unordered_map<std::string, std::string> strings = {{"one", "value 1"}, {"two", "value 2"}, {"three", "value 3"}})
  {
    return strings;
  }
}

TESTCASE(DefaultValue)
{
  define_unordered_map<std::unordered_map<std::string, std::string>>("StringUnorderedMap");
  define_global_function("default_unordered_map", &defaultUnorderedMap, Arg("strings") = std::unordered_map<std::string, std::string>{ {"one", "value 1"}, {"two", "value 2"}, {"three", "value 3"} });

  Module m = define_module("Testing");
  Object result = m.module_eval("default_unordered_map");
  std::unordered_map<std::string, std::string> actual = detail::From_Ruby<std::unordered_map<std::string, std::string>>().convert(result);

  std::unordered_map<std::string, std::string> expected{ {"one", "value 1"}, {"two", "value 2"}, {"three", "value 3"} };

  ASSERT_EQUAL(expected.size(), actual.size());
  ASSERT_EQUAL(expected["one"], actual["one"]);
  ASSERT_EQUAL(expected["two"], actual["two"]);
  ASSERT_EQUAL(expected["three"], actual["three"]);
}

namespace
{
  std::unordered_map<std::string, int> ints;
  std::unordered_map<std::string, float> floats;
  std::unordered_map<std::string, std::string> strings;

  void hashToUnorderedMap(std::unordered_map<std::string, int> aInts, std::unordered_map<std::string, float> aFloats, std::unordered_map<std::string, std::string> aStrings)
  {
    ints = aInts;
    floats = aFloats;
    strings = aStrings;
  }

  void hashToUnorderedMapRefs(std::unordered_map<std::string, int>& aInts, std::unordered_map<std::string, float>& aFloats, std::unordered_map<std::string, std::string>& aStrings)
  {
    ints = aInts;
    floats = aFloats;
    strings = aStrings;
  }

  void hashToUnorderedMapPointers(std::unordered_map<std::string, int>* aInts, std::unordered_map<std::string, float>* aFloats, std::unordered_map<std::string, std::string>* aStrings)
  {
    ints = *aInts;
    floats = *aFloats;
    strings = *aStrings;
  }
}

TESTCASE(HashToUnorderedMap)
{
  define_global_function("hash_to_unordered_map", &hashToUnorderedMap);

  Module m = define_module("Testing");

  std::string code = R"(hash_to_unordered_map({"seven" => 7, 
                                     "nine" => 9,
                                     "million" => 1_000_000},
                                    {"forty nine" => 49.0, 
                                     "seventy eight" => 78.0,
                                     "nine hundred ninety nine" => 999.0},
                                    {"one" => "one", 
                                     "two" => "two",
                                     "three" => "three"}))";

  m.module_eval(code);

  ASSERT_EQUAL(3u, ints.size());
  ASSERT_EQUAL(7, ints["seven"]);
  ASSERT_EQUAL(9, ints["nine"]);
  ASSERT_EQUAL(1'000'000, ints["million"]);

  ASSERT_EQUAL(3u, floats.size());
  ASSERT_EQUAL(49.0, floats["forty nine"]);
  ASSERT_EQUAL(78.0, floats["seventy eight"]);
  ASSERT_EQUAL(999.0, floats["nine hundred ninety nine"]);

  ASSERT_EQUAL(3u, strings.size());
  ASSERT_EQUAL("one", strings["one"]);
  ASSERT_EQUAL("two", strings["two"]);
  ASSERT_EQUAL("three", strings["three"]);
}

TESTCASE(HashToUnorderedMapRefs)
{
  define_global_function("hash_to_unordered_map_refs", &hashToUnorderedMapRefs);

  Module m = define_module("Testing");

  std::string code = R"(hash_to_unordered_map_refs({"eight" => 8, 
                                          "ten" => 10,
                                          "million one" => 1_000_001},
                                         {"fifty" => 50.0, 
                                          "seventy nine" => 79.0,
                                          "one thousand" => 1_000.0},
                                         {"eleven" => "eleven", 
                                          "twelve" => "twelve",
                                          "thirteen" => "thirteen"}))";
  m.module_eval(code);

  ASSERT_EQUAL(3u, ints.size());
  ASSERT_EQUAL(8, ints["eight"]);
  ASSERT_EQUAL(10, ints["ten"]);
  ASSERT_EQUAL(1'000'001, ints["million one"]);

  ASSERT_EQUAL(3u, floats.size());
  ASSERT_EQUAL(50.0, floats["fifty"]);
  ASSERT_EQUAL(79.0, floats["seventy nine"]);
  ASSERT_EQUAL(1'000.0, floats["one thousand"]);

  ASSERT_EQUAL(3u, strings.size());
  ASSERT_EQUAL("eleven", strings["eleven"]);
  ASSERT_EQUAL("twelve", strings["twelve"]);
  ASSERT_EQUAL("thirteen", strings["thirteen"]);
}

TESTCASE(HashToUnorderedMapPointers)
{
  define_global_function("hash_to_unordered_map_pointers", &hashToUnorderedMapPointers);

  Module m = define_module("Testing");

  std::string code = R"(hash_to_unordered_map_pointers({"nine" => 9, 
                                              "eleven" => 11,
                                              "million two" => 1_000_002},
                                             {"fifty one" => 51.0, 
                                              "eighty" => 80.0,
                                              "one thousand one" => 1_001.0},
                                             {"fourteen" => "fourteen", 
                                              "fifteen" => "fifteen",
                                              "sixteen" => "sixteen"}))";

  m.module_eval(code);

  ASSERT_EQUAL(3u, ints.size());
  ASSERT_EQUAL(9, ints["nine"]);
  ASSERT_EQUAL(11, ints["eleven"]);
  ASSERT_EQUAL(1'000'002, ints["million two"]);

  ASSERT_EQUAL(3u, floats.size());
  ASSERT_EQUAL(51.0, floats["fifty one"]);
  ASSERT_EQUAL(80.0, floats["eighty"]);
  ASSERT_EQUAL(1'001.0, floats["one thousand one"]);

  ASSERT_EQUAL(3u, strings.size());
  ASSERT_EQUAL("fourteen", strings["fourteen"]);
  ASSERT_EQUAL("fifteen", strings["fifteen"]);
  ASSERT_EQUAL("sixteen", strings["sixteen"]);
}

TESTCASE(HashToUnorderedMapWrongTypes)
{
  define_global_function("hash_to_unordered_map", &hashToUnorderedMap);

  Module m = define_module("Testing");

  std::string code = R"(hash_to_unordered_map({"seven" => 7, 
                                     "nine" => 9,
                                     "million" => 1_000_000},
                                    {"forty nine" => 49.0, 
                                     "seventy eight" => 78.0,
                                     "nine hundred ninety nine" => 999.0},
                                    {"one" => 50.0, 
                                     "two" => 79.0,
                                     "three" => 1000.0}))";

  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.module_eval(code),
    ASSERT_EQUAL("wrong argument type Float (expected String)", ex.what())
  );
}

TESTCASE(HashToUnorderedMapMixedTypes)
{
  define_global_function("hash_to_unordered_map", &hashToUnorderedMap);

  Module m = define_module("Testing");

  std::string code = R"(hash_to_unordered_map({"seven" => 7, 
                                     "nine" => "nine",
                                     "million" => true},
                                    {"forty nine" => 49.0, 
                                     "seventy eight" => 78.0,
                                     "nine hundred ninety nine" => 999.0},
                                    {"one" => "one", 
                                     "two" => "two",
                                     "three" => "three"}))";

  ASSERT_EXCEPTION_CHECK(
    Exception,
    m.module_eval(code),
    ASSERT_EQUAL("no implicit conversion of String into Integer", ex.what())
  );
}

TESTCASE(UnorderedMapToHash)
{
  Module m = define_module("Testing");
  Class c = makeUnorderedUnorderedMapClass();

  std::string code = R"(my_class = MyClass.new
                        unordered_map = my_class.stringUnorderedMap
                        hash = unordered_map.to_h)";

  Hash hash = m.module_eval(code);
  ASSERT_EQUAL(3u, hash.size());
  
  ASSERT_EQUAL("1", detail::From_Ruby<std::string>().convert(hash["One"].value()));
  ASSERT_EQUAL("2", detail::From_Ruby<std::string>().convert(hash["Two"].value()));
  ASSERT_EQUAL("3", detail::From_Ruby<std::string>().convert(hash["Three"].value()));
}
