#include <array>
#include <algorithm>

#include "../traits/rice_traits.hpp"
#include "NativeRegistry.hpp"
#include "to_ruby_defn.hpp"
#include "cpp_protect.hpp"

namespace Rice::detail
{
  template<typename Attribute_T>
  void NativeAttribute<Attribute_T>::define(VALUE klass, std::string name, Attribute_T attribute, AttrAccess access)
  {
    // Create a NativeAttribute that Ruby will call to read/write C++ variables
    NativeAttribute_T* native = new NativeAttribute_T(klass, name, std::forward<Attribute_T>(attribute), access);

    if (access == AttrAccess::ReadWrite || access == AttrAccess::Read)
    {
      // Tell Ruby to invoke the static method read to get the attribute value
      detail::protect(rb_define_method, klass, name.c_str(), (RUBY_METHOD_FUNC)&NativeAttribute_T::get, 0);

      // Add to native registry
      detail::Registries::instance.natives.add(klass, Identifier(name).id(), native);
    }

    if (access == AttrAccess::ReadWrite || access == AttrAccess::Write)
    {
      if (std::is_const_v<std::remove_pointer_t<T>>)
      {
        throw std::runtime_error(name + " is readonly");
      }

      // Define the write method name
      std::string setter = name + "=";

      // Tell Ruby to invoke the static method write to get the attribute value
      detail::protect(rb_define_method, klass, setter.c_str(), (RUBY_METHOD_FUNC)&NativeAttribute_T::set, 1);

      // Add to native registry
      detail::Registries::instance.natives.add(klass, Identifier(setter).id(), native);
    }
  }

  template<typename Attribute_T>
  inline VALUE NativeAttribute<Attribute_T>::get(VALUE self)
  {
    return cpp_protect([&]
    {
      using Native_Attr_T = NativeAttribute<Attribute_T>;
      Native_Attr_T* attr = detail::Registries::instance.natives.lookup<Native_Attr_T*>();
      return attr->read(self);
    });
  }

  template<typename Attribute_T>
  inline VALUE NativeAttribute<Attribute_T>::set(VALUE self, VALUE value)
  {
    return cpp_protect([&]
    {
      using Native_Attr_T = NativeAttribute<Attribute_T>;
      Native_Attr_T* attr = detail::Registries::instance.natives.lookup<Native_Attr_T*>();
      return attr->write(self, value);
    });
  }

  template<typename Attribute_T>
  NativeAttribute<Attribute_T>::NativeAttribute(VALUE klass, std::string name,
                                                             Attribute_T attribute, AttrAccess access)
    : klass_(klass), name_(name), attribute_(attribute), access_(access)
  {
  }

  template<typename Attribute_T>
  inline VALUE NativeAttribute<Attribute_T>::read(VALUE self)
  {
    using T_Unqualified = remove_cv_recursive_t<T>;
    if constexpr (std::is_member_object_pointer_v<Attribute_T>)
    {
      Receiver_T* nativeSelf = From_Ruby<Receiver_T*>().convert(self);
      return To_Ruby<T_Unqualified>().convert(nativeSelf->*attribute_);
    }
    else
    {
      return To_Ruby<T_Unqualified>().convert(*attribute_);
    }
  }

  template<typename Attribute_T>
  inline VALUE NativeAttribute<Attribute_T>::write(VALUE self, VALUE value)
  {
    if constexpr (std::is_fundamental_v<intrinsic_type<T>> && std::is_pointer_v<T>)
    {
      static_assert(true, "An fundamental value, such as an integer, cannot be assigned to an attribute that is a pointer");
    }
    else if constexpr (std::is_same_v<intrinsic_type<T>, std::string> && std::is_pointer_v<T>)
    {
      static_assert(true, "An string cannot be assigned to an attribute that is a pointer");
    }
    
    if constexpr (!std::is_null_pointer_v<Receiver_T>)
    {
      Receiver_T* nativeSelf = From_Ruby<Receiver_T*>().convert(self);
      nativeSelf->*attribute_ = From_Ruby<T_Unqualified>().convert(value);
    }
    else if constexpr (!std::is_const_v<std::remove_pointer_t<T>>)
    {
      *attribute_ = From_Ruby<T_Unqualified>().convert(value);
    }

    return value;
  }
} // Rice
