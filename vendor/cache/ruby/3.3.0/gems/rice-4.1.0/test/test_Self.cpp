#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

#include <memory>

using namespace Rice;

TESTSUITE(Self);

namespace
{
  class SelfClass
  {
  public:
    static inline int constructorCalls = 0;
    static inline int copyConstructorCalls = 0;
    static inline int moveConstructorCalls = 0;
    static inline int destructorCalls = 0;
    static inline int methodCalls = 0;

    static void reset()
    {
      constructorCalls = 0;
      copyConstructorCalls = 0;
      moveConstructorCalls = 0;
      destructorCalls = 0;
      methodCalls = 0;
    }

  public:
    SelfClass()
    {
      constructorCalls++;
    }

    ~SelfClass()
    {
      destructorCalls++;
    }

    SelfClass(const SelfClass& other)
    {
      copyConstructorCalls++;
    }

    SelfClass(SelfClass&& other)
    {
      moveConstructorCalls++;
    }

    SelfClass* selfPointer()
    {
      return this;
    }

    SelfClass& selfReference()
    {
      return *this;
    }

    SelfClass selfValue()
    {
      return *this;
    }
  };
}

SETUP(Self)
{
  embed_ruby();

  define_class<SelfClass>("SelfClass").
    define_constructor(Constructor<SelfClass>()).
    define_method("self_reference", &SelfClass::selfReference).
    define_method("self_pointer", &SelfClass::selfPointer).
    define_method("self_value", &SelfClass::selfValue).
    define_method("self_reference_lambda", [](SelfClass& self) -> SelfClass&
      {
        return self;
      }).
    define_method("self_pointer_lambda", [](SelfClass& self)
      {
        return &self;
      }).
    define_method("self_value_lambda", [](SelfClass& self)
      {
        return self;
      });
}

TESTCASE(SelfPointer)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_pointer");
  ASSERT(selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 == pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(0, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::destructorCalls);
}

TESTCASE(SelfReference)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_reference");
  ASSERT(selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 == pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(0, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::destructorCalls);
}

TESTCASE(SelfValue)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_value");
  ASSERT(!selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 != pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(1, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(1, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(1, SelfClass::destructorCalls);
}

TESTCASE(SelfPointerLambda)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_pointer_lambda");
  ASSERT(selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 == pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(0, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::destructorCalls);
}

TESTCASE(SelfReferenceLambda)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_reference_lambda");
  ASSERT(selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 == pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(0, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(0, SelfClass::destructorCalls);
}

TESTCASE(SelfValueLambda)
{
  SelfClass::reset();

  Module m = define_module("TestingModule");
  Object selfClass1 = m.module_eval("SelfClass.new");
  Object selfClass2 = selfClass1.call("self_value_lambda");
  ASSERT(!selfClass2.is_equal(selfClass1));

  SelfClass* pointer1 = detail::From_Ruby<SelfClass*>().convert(selfClass1);
  SelfClass* pointer2 = detail::From_Ruby<SelfClass*>().convert(selfClass2);
  ASSERT((pointer1 != pointer2));

  ASSERT_EQUAL(1, SelfClass::constructorCalls);
  ASSERT_EQUAL(1, SelfClass::copyConstructorCalls);
  ASSERT_EQUAL(1, SelfClass::moveConstructorCalls);
  ASSERT_EQUAL(1, SelfClass::destructorCalls);
}
