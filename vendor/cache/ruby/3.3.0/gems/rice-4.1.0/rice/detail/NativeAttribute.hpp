#ifndef Rice__detail__Native_Attribute__hpp_
#define Rice__detail__Native_Attribute__hpp_

#include "ruby.hpp"
#include "../traits/attribute_traits.hpp"

namespace Rice
{
  enum class AttrAccess
  {
    ReadWrite,
    Read,
    Write
  };

  namespace detail
  {
    template<typename Attribute_T>
    class NativeAttribute
    {
    public:
      using NativeAttribute_T = NativeAttribute<Attribute_T>;

      using T = typename attribute_traits<Attribute_T>::attr_type;
      using T_Unqualified = remove_cv_recursive_t<T>;
      using Receiver_T = typename attribute_traits<Attribute_T>::class_type;
    
    public:
      // Register attribute getter/setter with Ruby
      static void define(VALUE klass, std::string name, Attribute_T attribute, AttrAccess access = AttrAccess::ReadWrite);

      // Static member functions that Ruby calls to read an attribute value
      static VALUE get(VALUE self);

      // Static member functions that Ruby calls to write an attribute value
      static VALUE set(VALUE self, VALUE value);

    public:
      // Disallow creating/copying/moving
      NativeAttribute() = delete;
      NativeAttribute(const NativeAttribute_T&) = delete;
      NativeAttribute(NativeAttribute_T&&) = delete;
      void operator=(const NativeAttribute_T&) = delete;
      void operator=(NativeAttribute_T&&) = delete;

    protected:
      NativeAttribute(VALUE klass, std::string name, Attribute_T attr, AttrAccess access = AttrAccess::ReadWrite);

      // Invokes the wrapped function
      VALUE read(VALUE self);
      VALUE write(VALUE self, VALUE value);

    private:
      VALUE klass_;
      std::string name_;
      Attribute_T attribute_;
      AttrAccess access_;
    };
  } // detail
} // Rice

#include "NativeAttribute.ipp"

#endif // Rice__detail__Native_Attribute__hpp_
