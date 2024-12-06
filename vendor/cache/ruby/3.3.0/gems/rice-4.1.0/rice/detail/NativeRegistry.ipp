
// Ruby 2.7 now includes a similarly named macro that uses templates to
// pick the right overload for the underlying function. That doesn't work
// for our cases because we are using this method dynamically and get a
// compilation error otherwise. This removes the macro and lets us fall
// back to the C-API underneath again.
#undef rb_define_method_id

#include "RubyFunction.hpp"

namespace Rice::detail
{
  // Effective Java (2nd edition)
  // https://stackoverflow.com/a/2634715
  inline size_t NativeRegistry::key(VALUE klass, ID id)
  {
    if (rb_type(klass) == T_ICLASS)
    {
      klass = detail::protect(rb_class_of, klass);
    }

    uint32_t prime = 53;
    return (prime + klass) * prime + id;
  }

  inline void NativeRegistry::add(VALUE klass, ID method_id, std::any callable)
  {
    // Now store data about it
    this->natives_[key(klass, method_id)] = callable;
  }

  template <typename Return_T>
  inline Return_T NativeRegistry::lookup()
  {
    ID method_id;
    VALUE klass;
    if (!rb_frame_method_id_and_class(&method_id, &klass))
    {
      rb_raise(rb_eRuntimeError, "Cannot get method id and class for function");
    }

    return this->lookup<Return_T>(klass, method_id);
  }

  template <typename Return_T>
  inline Return_T NativeRegistry::lookup(VALUE klass, ID method_id)
  {
    auto iter = this->natives_.find(key(klass, method_id));
    if (iter == this->natives_.end())
    {
      rb_raise(rb_eRuntimeError, "Could not find data for klass and method id");
    }

    std::any data = iter->second;
    return std::any_cast<Return_T>(data);
  }
}
