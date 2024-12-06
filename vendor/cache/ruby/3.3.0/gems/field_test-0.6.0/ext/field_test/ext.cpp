#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include "bayestest.hpp"

using bayestest::BinaryTest;

extern "C"
void Init_ext() {
  auto rb_mFieldTest = Rice::define_module("FieldTest");

  Rice::define_class_under<BinaryTest>(rb_mFieldTest, "BinaryTest")
    .define_constructor(Rice::Constructor<BinaryTest>())
    .define_method("add", &BinaryTest::add)
    .define_method("probabilities", &BinaryTest::probabilities);
}
