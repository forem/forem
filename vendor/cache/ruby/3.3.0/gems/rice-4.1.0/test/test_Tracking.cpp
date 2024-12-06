#include "unittest.hpp"
#include "embed_ruby.hpp"

#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Tracking);

namespace
{
  class MyClass
  {
  };

  class Factory
  {
  public:
    static void reset()
    {
      delete Factory::instance_;
      Factory::instance_ = nullptr;
    }

  public:
    Factory* factory()
    {
      return this;
    }

    MyClass* transferPointer()
    {
      return new MyClass();
    }

    MyClass* keepPointer()
    {
      return this->instance();
    }

    MyClass& keepReference()
    {
      return *this->instance();
    }

    MyClass value()
    {
      return MyClass();
    }

    MyClass moveValue()
    {
      return std::move(MyClass());
    }

    MyClass* instance()
    {
      if (!instance_)
      {
        instance_ = new MyClass();
      }
      return instance_;
    }

  public:
    static inline MyClass* instance_ = nullptr;
  };
}

SETUP(Tracking)
{
  embed_ruby();

  define_class<MyClass>("MyClass");

  define_class<Factory>("Factory").
    define_constructor(Constructor<Factory>()).
    define_method("factory", &Factory::factory).
    define_method("value", &Factory::value).
    define_method("move_value", &Factory::moveValue).
    define_method("transfer_pointer", &Factory::transferPointer, Return().takeOwnership()).
    define_method("keep_pointer", &Factory::keepPointer).
    define_method("copy_reference", &Factory::keepReference, Return().takeOwnership()).
    define_method("keep_reference", &Factory::keepReference);
}

TEARDOWN(Tracking)
{
  detail::Registries::instance.instances.isEnabled = true;
}

TESTCASE(TransferPointer)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");
  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("transfer_pointer");
  Data_Object<MyClass> my_class2 = factory.call("transfer_pointer");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_NOT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(KeepPointer)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");

  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("keep_pointer");
  Data_Object<MyClass> my_class2 = factory.call("keep_pointer");

  ASSERT(my_class1.is_equal(my_class2));
  ASSERT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(KeepPointerWithoutTracking)
{
  detail::Registries::instance.instances.isEnabled = false;
  Factory::reset();

  Module m = define_module("TestingModule");

  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("keep_pointer");
  Data_Object<MyClass> my_class2 = factory.call("keep_pointer");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(KeepReference)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");

  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("keep_reference");
  Data_Object<MyClass> my_class2 = factory.call("keep_reference");

  ASSERT(my_class1.is_equal(my_class2));
  ASSERT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(KeepReferenceWithoutTracking)
{
  detail::Registries::instance.instances.isEnabled = false;
  Factory::reset();

  Module m = define_module("TestingModule");

  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("keep_reference");
  Data_Object<MyClass> my_class2 = factory.call("keep_reference");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(CopyReference)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");
  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("copy_reference");
  Data_Object<MyClass> my_class2 = factory.call("copy_reference");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_NOT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(TransferValue)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");
  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("value");
  Data_Object<MyClass> my_class2 = factory.call("value");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_NOT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(MoveValue)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");
  Object factory = m.module_eval("Factory.new");

  Data_Object<MyClass> my_class1 = factory.call("move_value");
  Data_Object<MyClass> my_class2 = factory.call("move_value");

  ASSERT(!my_class1.is_equal(my_class2));
  ASSERT_NOT_EQUAL(my_class1.get(), my_class2.get());
}

TESTCASE(RubyObjectGced)
{
  detail::Registries::instance.instances.isEnabled = true;
  Factory::reset();

  Module m = define_module("TestingModule");
  Object factory = m.module_eval("Factory.new");

  {
    // Track the C++ object returned by keepPointer
    Data_Object<MyClass> my_class1 = factory.call("keep_pointer");
    rb_gc_start();
  }

  // Make my_class1 invalid
  rb_gc_start();

  // Get the object again - this should *not* return the previous value
  Data_Object<MyClass> my_class2 = factory.call("keep_pointer");

  // Call a method on the ruby object
  String className = my_class2.class_name();
  ASSERT_EQUAL(std::string("MyClass"), className.str());
}
