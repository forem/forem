#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Iterator);

SETUP(Iterator)
{
  embed_ruby();
}

namespace
{
  class Container
  {
  public:
    Container(int* array, size_t length)
      : array_(array)
      , length_(length)
    {
    }

    // Custom names to make sure we call the function pointers rather than
    // expectable default names.
    int* beginFoo() { return array_; }
    int* endBar() { return array_ + length_; }

  private:
    int* array_;
    size_t length_;
  };
} // namespace

TESTCASE(define_array_iterator)
{
  define_class<Container>("Container")
    .define_constructor(Constructor<Container, int*, size_t>())
    .define_iterator(&Container::beginFoo, &Container::endBar);

  int array[] = { 1, 2, 3 };
  Container* container = new Container(array, 3);

  Object wrapped_container = Data_Object<Container>(container);

  Array a = wrapped_container.instance_eval("a = []; each() { |x| a << x }; a");
  ASSERT_EQUAL(3u, a.size());
  ASSERT_EQUAL(Object(detail::to_ruby(1)), a[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), a[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), a[2]);
}

namespace
{
  struct Data
  {
    Data(uint32_t value)
    {
      this->index = value;
    }

    uint32_t index;
  };

  class ContainerValues
  {
  public:
    ContainerValues()
    {
      this->data_ = { {1}, {2}, {3}};
    }

    std::vector<Data>::iterator begin()
    {
      return this->data_.begin();
    }

    std::vector<Data>::iterator end()
    {
      return this->data_.end();
    }

    std::vector<Data>::const_iterator cbegin() const
    {
      return this->data_.cbegin();
    }

    std::vector<Data>::const_iterator cend() const
    {
      return this->data_.cend();
    }

    std::vector<Data> data_;
  };

  class ContainerPointers
  {
  public:
    ContainerPointers()
    {
      this->data_ = { new Data{1}, new Data{2},  new Data{3} };
    }

    ~ContainerPointers()
    {
      for (Data* data : this->data_)
      {
        delete data;
      }
    }

    std::vector<Data*>::iterator begin()
    {
      return this->data_.begin();
    }

    std::vector<Data*>::iterator end()
    {
      return this->data_.end();
    }

    std::vector<Data*>::reverse_iterator rbegin()
    {
      return this->data_.rbegin();
    }

    std::vector<Data*>::reverse_iterator rend()
    {
      return this->data_.rend();
    }

    std::vector<Data*> data_;
  };
}

template <>
struct detail::To_Ruby<Data>
{
  static VALUE convert(const Data& data)
  {
    return detail::to_ruby(data.index);
  }
};

template <>
struct detail::To_Ruby<Data*>
{
  static VALUE convert(const Data* data)
  {
    return detail::to_ruby(data->index);
  }
};

TESTCASE(iterator_value)
{
  define_class<ContainerValues>("ContainerValues")
      .define_constructor(Constructor<ContainerValues>())
      .define_iterator(&ContainerValues::begin, &ContainerValues::end);

  ContainerValues* container = new ContainerValues();
  Object wrapper = Data_Object<ContainerValues>(container);

  Array a = wrapper.instance_eval("a = []; each() { |x| a << x }; a");
  ASSERT_EQUAL(3u, a.size());

  ASSERT_EQUAL(Object(detail::to_ruby(1)), a[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), a[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), a[2]);
}

TESTCASE(const_iterator_value)
{
  define_class<ContainerValues>("ContainerValues")
    .define_constructor(Constructor<ContainerValues>())
    .define_iterator(&ContainerValues::cbegin, &ContainerValues::cend);

  Module m = define_module("TestingModule");

  std::string code = R"(result = []
                        container = ContainerValues.new
                        container.each do |x|
                          result << x
                        end
                        result)";

  Array result = m.module_eval(code);

  ASSERT_EQUAL(3u, result.size());
  ASSERT_EQUAL(Object(detail::to_ruby(1)), result[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), result[2]);
}

TESTCASE(iterator_pointer)
{
  define_class<ContainerPointers>("ContainerPointers")
    .define_constructor(Constructor<ContainerPointers>())
    .define_iterator(&ContainerPointers::begin, &ContainerPointers::end);

  ContainerPointers* container = new ContainerPointers();
  Object wrapper = Data_Object<ContainerPointers>(container);

  Module m = define_module("TestingModule");

  std::string code = R"(result = []
                        container = ContainerPointers.new
                        container.each do |x|
                          result << x
                        end
                        result)";

  Array result = m.module_eval(code);

  ASSERT_EQUAL(3u, result.size());
  ASSERT_EQUAL(Object(detail::to_ruby(1)), result[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), result[2]);
}

TESTCASE(two_iterator_pointer)
{
  define_class<ContainerPointers>("ContainerPointers")
    .define_constructor(Constructor<ContainerPointers>())
    .define_iterator(&ContainerPointers::begin, &ContainerPointers::end)
    .define_iterator(&ContainerPointers::rbegin, &ContainerPointers::rend, "reach");

  ContainerPointers* container = new ContainerPointers();
  Object wrapper = Data_Object<ContainerPointers>(container);

  Module m = define_module("TestingModule");

  std::string code = R"(result = []
                        container = ContainerPointers.new
                        container.each do |x|
                          result << x
                        end
                        container.reach do |x|
                          result << x
                        end
                        result)";

  Array result = m.module_eval(code);

  ASSERT_EQUAL(6u, result.size());
  ASSERT_EQUAL(Object(detail::to_ruby(1)), result[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), result[2]);
  ASSERT_EQUAL(Object(detail::to_ruby(3)), result[3]);
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[4]);
  ASSERT_EQUAL(Object(detail::to_ruby(1)), result[5]);
}

TESTCASE(map)
{
  define_class<ContainerPointers>("ContainerPointers")
    .define_constructor(Constructor<ContainerPointers>())
    .define_iterator(&ContainerPointers::begin, &ContainerPointers::end);

  Module m = define_module("Testing");

  std::string code = R"(container = ContainerPointers.new
                        container.map do |x|
                          x * 2
                        end)";

  Array result = m.module_eval(code);

  ASSERT_EQUAL(3u, result.size());
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(4)), result[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(6)), result[2]);
}

TESTCASE(to_enum)
{
  Module m = define_module("TestingModule");

  std::string code = R"(container = ContainerPointers.new
                        container.each.map do |x|
                          x * 2
                        end)";

  Array result = m.module_eval(code);

  ASSERT_EQUAL(3u, result.size());
  ASSERT_EQUAL(Object(detail::to_ruby(2)), result[0]);
  ASSERT_EQUAL(Object(detail::to_ruby(4)), result[1]);
  ASSERT_EQUAL(Object(detail::to_ruby(6)), result[2]);
}