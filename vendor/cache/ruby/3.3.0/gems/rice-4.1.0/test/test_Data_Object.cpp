#include <ruby/version.h>

#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Data_Object);

namespace
{
  bool test_destructor_called = false;
  bool test_ruby_mark_called = false;

  struct MyDataType
  {
    MyDataType() : x(42)
    {
    }

    ~MyDataType()
    {
      test_destructor_called = true;
    }
    
    int x;
  };

  struct Bar
  {
  };
}

namespace Rice
{
  template<>
  void ruby_mark(MyDataType* myDataType)
  {
    test_ruby_mark_called = true;
  }
}

SETUP(Data_Object)
{
  embed_ruby();

  if (!Data_Type<MyDataType>::is_bound())
  {
    Class object(rb_cObject);
    if(object.const_defined("MyDataType"))
    {
      object.remove_const("MyDataType");
    }

    define_class<MyDataType>("MyDataType");
    define_class<Bar>("Bar");
  }
}

TESTCASE(construct_from_pointer)
{
  MyDataType* myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType, wrapped_foo.get());
  ASSERT_EQUAL(Data_Type<MyDataType>::klass(), wrapped_foo.class_of());
  ASSERT_EQUAL(myDataType, detail::unwrap<MyDataType>(wrapped_foo, Data_Type<MyDataType>::ruby_data_type()));
}

TESTCASE(construct_from_ruby_object)
{
  MyDataType * myDataType = new MyDataType;
  VALUE wrapped_foo = detail::wrap(Data_Type<MyDataType>::klass(), Data_Type<MyDataType>::ruby_data_type(), myDataType, true);

  Data_Object<MyDataType> data_object_foo(wrapped_foo);
  ASSERT_EQUAL(myDataType, data_object_foo.get());
  ASSERT_EQUAL(Data_Type<MyDataType>::klass(), data_object_foo.class_of());
  ASSERT_EQUAL(RTYPEDDATA(wrapped_foo), RTYPEDDATA(data_object_foo.value()));
  ASSERT_EQUAL(myDataType, detail::unwrap<MyDataType>(wrapped_foo, Data_Type<MyDataType>::ruby_data_type()));
}

TESTCASE(construct_from_ruby_object_and_wrong_class)
{
  MyDataType * myDataType = new MyDataType;
  VALUE wrapped_foo = detail::wrap(Data_Type<MyDataType>::klass(), Data_Type<MyDataType>::ruby_data_type(), myDataType, true);

  ASSERT_EXCEPTION_CHECK(
    Exception,
    Data_Object<Bar> bar(wrapped_foo),
    ASSERT_EQUAL(rb_eTypeError, CLASS_OF(ex.value())));

  ASSERT_EXCEPTION_CHECK(
    Exception,
    Data_Object<Bar> bar(wrapped_foo),
    ASSERT_EQUAL("Wrong argument type. Expected: Bar. Received: MyDataType.", ex.what()));
}

TESTCASE(copy_construct)
{
  MyDataType * myDataType = new MyDataType;
  VALUE wrapped_foo = detail::wrap(Data_Type<MyDataType>::klass(), Data_Type<MyDataType>::ruby_data_type(), myDataType, true);
  Data_Object<MyDataType> orig_data_object_foo(wrapped_foo);
  Data_Object<MyDataType> data_object_foo(orig_data_object_foo);

  ASSERT_EQUAL(myDataType, data_object_foo.get());
  ASSERT_EQUAL(Data_Type<MyDataType>::klass(), data_object_foo.class_of());
  ASSERT_EQUAL(RTYPEDDATA(wrapped_foo), RTYPEDDATA(data_object_foo.value()));
  ASSERT_EQUAL(myDataType, detail::unwrap<MyDataType>(wrapped_foo, Data_Type<MyDataType>::ruby_data_type()));
}

TESTCASE(move_construct)
{
  MyDataType* myDataType = new MyDataType;

  Data_Object<MyDataType> wrapper1(myDataType);
  Data_Object<MyDataType> wrapper2(std::move(wrapper1));

  ASSERT_EQUAL(myDataType, wrapper2.get());
  ASSERT((wrapper1.get() == nullptr));
}

TESTCASE(move_assign)
{
  MyDataType* foo1 = new MyDataType;
  Data_Object<MyDataType> wrapper1(foo1);

  MyDataType* foo2 = new MyDataType;
  Data_Object<MyDataType> wrapper2(foo2);

  wrapper2 = std::move(wrapper1);

  ASSERT_EQUAL(foo1, wrapper2.get());
  ASSERT((wrapper1.get() == nullptr));
}

TESTCASE(dereference)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType, &*wrapped_foo);
}

TESTCASE(arrow)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(42, myDataType->x);
}

TESTCASE(get)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType, wrapped_foo.get());
}

TESTCASE(to_ruby)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(String("MyDataType"), wrapped_foo.class_name());
}

TESTCASE(from_ruby)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType* myDataType = new MyDataType();
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType, wrapped_foo.get());
}

TESTCASE(from_ruby_const_ref)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType->x, detail::From_Ruby<MyDataType const &>().convert(wrapped_foo).x);
}

TESTCASE(from_ruby_copy)
{
  Data_Type<MyDataType> rb_cFoo;
  MyDataType * myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  ASSERT_EQUAL(myDataType->x, detail::From_Ruby<MyDataType>().convert(wrapped_foo).x);
}

TESTCASE(ruby_custom_mark)
{
  test_ruby_mark_called = false;

  MyDataType* myDataType = new MyDataType;
  Data_Object<MyDataType> wrapped_foo(myDataType);
  rb_gc_start();

  ASSERT_EQUAL(true, test_ruby_mark_called);
}

TESTCASE(ruby_custom_free)
{
  test_ruby_mark_called = false;
  test_destructor_called = false;

  {
    // Put this code in a block so wrapped_foo is destroyed at the end of it.
    // That will set its value field to Qnil allowing myDataType to be freed
    MyDataType* myDataType = new MyDataType;
    Data_Object<MyDataType> wrapped_foo(myDataType, true);

    // Force a mark
    rb_gc_start();
    ASSERT_EQUAL(true, test_ruby_mark_called);
  }

  // Force a free
  rb_gc_start();

  // Some versions of Ruby's and compilers think the Ruby value in wrapped_foo is still
  // alive. Thus the rb_gc_start call results in a mark and not a free
#if defined(__MINGW64__) && RUBY_API_VERSION_MAJOR == 3 && RUBY_API_VERSION_MINOR == 2
  // do nothing
#elif defined(__APPLE__) && RUBY_API_VERSION_MAJOR == 2 && RUBY_API_VERSION_MINOR == 7
  // do nothing
#else
//  ASSERT_EQUAL(true, test_destructor_called);
#endif
}
