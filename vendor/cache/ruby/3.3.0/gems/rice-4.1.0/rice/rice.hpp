#ifndef Rice__hpp_
#define Rice__hpp_

// Traits
#include "detail/ruby.hpp"
#include "traits/rice_traits.hpp"
#include "traits/function_traits.hpp"
#include "traits/method_traits.hpp"
#include "traits/attribute_traits.hpp"

// Code for C++ to call Ruby
#include "Exception_defn.hpp"
#include "detail/Jump_Tag.hpp"
#include "detail/RubyFunction.hpp"

// Code for Ruby to call C++
#include "detail/ExceptionHandler.hpp"
#include "detail/Type.hpp"
#include "detail/TypeRegistry.hpp"
#include "detail/InstanceRegistry.hpp"
#include "detail/HandlerRegistry.hpp"
#include "detail/NativeRegistry.hpp"
#include "detail/Registries.hpp"
#include "detail/cpp_protect.hpp"
#include "detail/Wrapper.hpp"
#include "Return.hpp"
#include "Arg.hpp"
#include "detail/MethodInfo.hpp"
#include "detail/from_ruby.hpp"
#include "detail/to_ruby.hpp"
#include "Identifier.hpp"
#include "Exception.ipp"
#include "detail/NativeAttribute.hpp"
#include "detail/NativeFunction.hpp"
#include "detail/NativeIterator.hpp"
#include "HandlerRegistration.hpp"

// C++ classes for using the Ruby API
#include "cpp_api/Object.hpp"
#include "cpp_api/Builtin_Object.hpp"
#include "cpp_api/String.hpp"
#include "cpp_api/Array.hpp"
#include "cpp_api/Hash.hpp"
#include "cpp_api/Symbol.hpp"
#include "cpp_api/Module.hpp"
#include "cpp_api/Class.hpp"
#include "cpp_api/Struct.hpp"
#include "Address_Registration_Guard.hpp"
#include "global_function.hpp"

// Code involed in creating custom DataTypes (ie, Ruby classes that wrap C++ classes)
#include "ruby_mark.hpp"
#include "detail/default_allocation_func.hpp"
#include "Director.hpp"
#include "Data_Type.hpp"
#include "detail/default_allocation_func.ipp"
#include "Constructor.hpp"
#include "Data_Object.hpp"
#include "Enum.hpp"

// Dependent on Module, Class, Array and String
#include "forward_declares.ipp"

#endif // Rice__hpp_
