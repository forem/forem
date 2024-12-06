#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include <memory>

using namespace Rice;

TESTSUITE(SmartPointer);

namespace
{
  class MyClass
  {
  public:
    static inline int32_t constructorCalls = 0;
    static inline int32_t copyConstructorCalls = 0;
    static inline int32_t moveConstructorCalls = 0;
    static inline int32_t destructorCalls = 0;

    static void reset()
    {
      constructorCalls = 0;
      copyConstructorCalls = 0;
      moveConstructorCalls = 0;
      destructorCalls = 0;
    }

  public:
    int flag = 0;

  public:
    MyClass()
    {
      constructorCalls++;
    }

    ~MyClass()
    {
      destructorCalls++;
    }

    MyClass(const MyClass& other): flag(other.flag)
    {
      copyConstructorCalls++;
    }

    MyClass(MyClass&& other) : flag(other.flag)
    {
      moveConstructorCalls++;
    }

    void setFlag(int value)
    {
      this->flag = value;
    }
  };

  class Factory
  {
  public:
    std::unique_ptr<MyClass> transfer()
    {
      return std::make_unique<MyClass>();
    }

    std::shared_ptr<MyClass> share()
    {
      if (!instance_)
      {
        instance_ = std::make_shared<MyClass>();
      }
      return instance_;
    }

  public:
    static inline std::shared_ptr<MyClass> instance_;
  };

  int extractFlagUniquePtrRef(std::unique_ptr<MyClass>& myClass)
  {
    return myClass->flag;
  }

  int extractFlagSharedPtr(std::shared_ptr<MyClass> myClass)
  {
    return myClass->flag;
  }

  int extractFlagSharedPtrRef(std::shared_ptr<MyClass>& myClass)
  {
    return myClass->flag;
  }
}

SETUP(SmartPointer)
{
  embed_ruby();

  define_class<MyClass>("MyClass").
    define_method("set_flag", &MyClass::setFlag);

  define_class<Factory>("Factory").
    define_constructor(Constructor<Factory>()).
    define_method("transfer", &Factory::transfer).
    define_method("share", &Factory::share);

  define_global_function("extract_flag_unique_ptr_ref", &extractFlagUniquePtrRef);
  define_global_function("extract_flag_shared_ptr", &extractFlagSharedPtr);
  define_global_function("extract_flag_shared_ptr_ref", &extractFlagSharedPtrRef);
}

TESTCASE(TransferOwnership)
{
  MyClass::reset();

  Module m = define_module("TestingModule");

  std::string code = R"(factory = Factory.new
                        10.times do |i|
                          my_class = factory.transfer
                          my_class.set_flag(i)
                          my_class = nil
                        end)";

  m.module_eval(code);
  rb_gc_start();

  ASSERT_EQUAL(10, MyClass::constructorCalls);
  ASSERT_EQUAL(0, MyClass::copyConstructorCalls);
  ASSERT_EQUAL(0, MyClass::moveConstructorCalls);
  ASSERT_EQUAL(10, MyClass::destructorCalls);
  ASSERT(!Factory::instance_);
}

TESTCASE(ShareOwnership)
{
  MyClass::reset();

  Module m = define_module("TestingModule");

  // Create ruby objects that point to the same instance of MyClass
  std::string code = R"(factory = Factory.new
                        10.times do |i|
                          my_class = factory.share
                          my_class.set_flag(i)
                        end)";

  m.module_eval(code);
  rb_gc_start();

  ASSERT_EQUAL(1, MyClass::constructorCalls);
  ASSERT_EQUAL(0, MyClass::copyConstructorCalls);
  ASSERT_EQUAL(0, MyClass::moveConstructorCalls);
  ASSERT_EQUAL(0, MyClass::destructorCalls);
  ASSERT_EQUAL(9, Factory::instance_->flag);
}

TESTCASE(UniquePtrRefParameter)
{
  MyClass::reset();

  Module m = define_module("TestingModule");

  std::string code = R"(factory = Factory.new
                        my_class = factory.transfer
                        my_class.set_flag(7)
                        extract_flag_unique_ptr_ref(my_class))";

  Object result = m.module_eval(code);
}

TESTCASE(SharedPtrParameter)
{
  MyClass::reset();

  Module m = define_module("TestingModule");

  std::string code = R"(factory = Factory.new
                        my_class = factory.share
                        my_class.set_flag(7)
                        extract_flag_shared_ptr(my_class))";
 
  Object result = m.module_eval(code);
}

TESTCASE(SharedPtrRefParameter)
{
  MyClass::reset();

  Module m = define_module("TestingModule");

  std::string code = R"(factory = Factory.new
                        my_class = factory.share
                        my_class.set_flag(7)
                        extract_flag_shared_ptr_ref(my_class))";

  Object result = m.module_eval(code);
}