#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Memory_Management);

SETUP(Memory_Management)
{
  embed_ruby();
}

namespace
{
  class TestClass {
    double tmp;
    public:
      TestClass() {tmp=0;}

      double getTmp() {
        return tmp;
      }

      void setTmp(double x) {
        tmp = x;
      }
  };

  TestClass returnTestClass() {
    TestClass x = TestClass();
    x.setTmp(8);
    return x;
  }
}

TESTCASE(allows_copy_contructors_to_work)
{
  define_class<TestClass>("TestClass")
    .define_method("tmp=", &TestClass::setTmp)
    .define_method("tmp", &TestClass::getTmp);

  define_global_function("return_test_class", &returnTestClass);

  Module m = define_module("TestingModule");

  Object result = m.module_eval("return_test_class.tmp");
  ASSERT_EQUAL(8.0, detail::From_Ruby<double>().convert(result.value()));
}
