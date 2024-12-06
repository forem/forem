#ifndef Rice_NativeIterator__hpp_
#define Rice_NativeIterator__hpp_

#include "traits/function_traits.hpp"

namespace Rice::detail
{
  template<typename T, typename Iterator_Func_T>
  class NativeIterator
  {
  public:
    using NativeIterator_T = NativeIterator<T, Iterator_Func_T>;
    using Iterator_T = typename function_traits<Iterator_Func_T>::return_type;
    using Value_T = typename std::iterator_traits<Iterator_T>::value_type;
    using Difference_T = typename std::iterator_traits<Iterator_T>::difference_type;

  public:
    // Register function with Ruby
    void static define(VALUE klass, std::string method_name, Iterator_Func_T begin, Iterator_Func_T end);

    // Static member function that Ruby calls
    static VALUE call(VALUE self);

  public:
    // Disallow creating/copying/moving
    NativeIterator() = delete;
    NativeIterator(const NativeIterator_T&) = delete;
    NativeIterator(NativeIterator_T&&) = delete;
    void operator=(const NativeIterator_T&) = delete;
    void operator=(NativeIterator_T&&) = delete;

    VALUE operator()(VALUE self);

  protected:
    NativeIterator(VALUE klass, std::string method_name, Iterator_Func_T begin, Iterator_Func_T end);

  private:
    VALUE createRubyEnumerator(VALUE self);

  private:
    VALUE klass_;
    std::string method_name_;
    Iterator_Func_T begin_;
    Iterator_Func_T end_;
  };
}
#include "NativeIterator.ipp"

#endif // Rice_NativeIterator__hpp_