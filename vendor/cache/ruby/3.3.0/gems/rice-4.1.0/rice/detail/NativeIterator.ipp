#include <iterator>
#include <functional>
#include <type_traits>

#include "cpp_protect.hpp"
#include "NativeRegistry.hpp"

namespace Rice::detail
{
  template <typename T, typename Iterator_Func_T>
  inline void NativeIterator<T, Iterator_Func_T>::define(VALUE klass, std::string method_name, Iterator_Func_T begin, Iterator_Func_T end)
  {
    // Tell Ruby to invoke the static method call on this class
    detail::protect(rb_define_method, klass, method_name.c_str(), (RUBY_METHOD_FUNC)&NativeIterator_T::call, 0);

    // Now create a NativeIterator instance and save it to the natives registry keyed on
    // Ruby klass and method id. There may be multiple NativeIterator instances
    // because the same C++ method could be mapped to multiple Ruby methods.
    NativeIterator_T* native = new NativeIterator_T(klass, method_name, begin, end);
    detail::Registries::instance.natives.add(klass, Identifier(method_name).id(), native);
  }

  template<typename T, typename Iterator_Func_T>
  inline VALUE NativeIterator<T, Iterator_Func_T>::call(VALUE self)
  {
    // Look up the native function based on the Ruby klass and method id
    NativeIterator_T* nativeIterator = detail::Registries::instance.natives.lookup<NativeIterator_T*>();

    return cpp_protect([&]
    {
      return nativeIterator->operator()(self);
    });
  }

  template <typename T, typename Iterator_Func_T>
  inline NativeIterator<T, Iterator_Func_T>::NativeIterator(VALUE klass, std::string method_name, Iterator_Func_T begin, Iterator_Func_T end) :
    klass_(klass), method_name_(method_name), begin_(begin), end_(end)
  {
  }

  template<typename T, typename Iterator_Func_T>
  inline VALUE NativeIterator<T, Iterator_Func_T>::createRubyEnumerator(VALUE self)
  {
    auto rb_size_function = [](VALUE recv, VALUE argv, VALUE eobj) -> VALUE
    {
      // Since we can't capture VALUE self from above (because then we can't send
      // this lambda to rb_enumeratorize_with_size), extract it from recv
      return cpp_protect([&]
      {
        // Get the iterator instance
        using Iter_T = NativeIterator<T, Iterator_Func_T>;
        // Class is easy
        VALUE klass = protect(rb_class_of, recv);
        // Read the method_id from an attribute we added to the enumerator instance
        ID method_id = protect(rb_ivar_get, eobj, rb_intern("rice_method"));
        Iter_T* iterator = detail::Registries::instance.natives.lookup<Iter_T*>(klass, method_id);

        // Get the wrapped C++ instance
        T* receiver = detail::From_Ruby<T*>().convert(recv);

        // Get the distance
        Iterator_T begin = std::invoke(iterator->begin_, *receiver);
        Iterator_T end = std::invoke(iterator->end_, *receiver);
        Difference_T distance = std::distance(begin, end);

        return detail::To_Ruby<Difference_T>().convert(distance);
      });
    };

    VALUE method_sym = Identifier(this->method_name_).to_sym();
    VALUE enumerator = protect(rb_enumeratorize_with_size, self, method_sym, 0, nullptr, rb_size_function);
    
    // Hack the enumerator object by storing name_ on the enumerator object so
    // the rb_size_function above has access to it
    ID method_id = Identifier(this->method_name_).id();
    protect(rb_ivar_set, enumerator, rb_intern("rice_method"), method_id  );

    return enumerator;
  }

  template<typename T, typename Iterator_Func_T>
  inline VALUE NativeIterator<T, Iterator_Func_T>::operator()(VALUE self)
  {
    if (!protect(rb_block_given_p))
    {
      return createRubyEnumerator(self);
    }
    else
    {
      T* receiver = detail::From_Ruby<T*>().convert(self);
      Iterator_T it = std::invoke(this->begin_, *receiver);
      Iterator_T end = std::invoke(this->end_, *receiver);

      for (; it != end; ++it)
      {
        protect(rb_yield, detail::To_Ruby<Value_T>().convert(*it));
      }

      return self;
    }
  }
}