#include <array>
#include <algorithm>
#include <stdexcept>

#include "cpp_protect.hpp"
#include "to_ruby_defn.hpp"
#include "NativeRegistry.hpp"

namespace Rice::detail
{
  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  void NativeFunction<From_Ruby_T, Function_T, IsMethod>::define(VALUE klass, std::string method_name, Function_T function, MethodInfo* methodInfo)
  {
    // Tell Ruby to invoke the static method call on this class
    detail::protect(rb_define_method, klass, method_name.c_str(), (RUBY_METHOD_FUNC)&NativeFunction_T::call, -1);

    // Now create a NativeFunction instance and save it to the natives registry keyed on
    // Ruby klass and method id. There may be multiple NativeFunction instances
    // because the same C++ method could be mapped to multiple Ruby methods.
    NativeFunction_T* native = new NativeFunction_T(klass, method_name, std::forward<Function_T>(function), methodInfo);
    detail::Registries::instance.natives.add(klass, Identifier(method_name).id(), native);
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  VALUE NativeFunction<From_Ruby_T, Function_T, IsMethod>::call(int argc, VALUE* argv, VALUE self)
  {
    // Look up the native function based on the Ruby klass and method id
    NativeFunction_T* nativeFunction = detail::Registries::instance.natives.lookup<NativeFunction_T*>();

    // Execute the function but make sure to catch any C++ exceptions!
    return cpp_protect([&]
    {
      return nativeFunction->operator()(argc, argv, self);
    });
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  NativeFunction<From_Ruby_T, Function_T, IsMethod>::NativeFunction(VALUE klass, std::string method_name, Function_T function, MethodInfo* methodInfo)
    : klass_(klass), method_name_(method_name), function_(function), methodInfo_(methodInfo)
  {
   // Create a tuple of NativeArgs that will convert the Ruby values to native values. For 
    // builtin types NativeArgs will keep a copy of the native value so that it 
    // can be passed by reference or pointer to the native function. For non-builtin types
    // it will just pass the value through.
    auto indices = std::make_index_sequence<std::tuple_size_v<Arg_Ts>>{};
    this->fromRubys_ = this->createFromRuby(indices);

    this->toRuby_ = this->createToRuby();
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  template<typename T, std::size_t I>
  From_Ruby<T> NativeFunction<From_Ruby_T, Function_T, IsMethod>::createFromRuby()
  {
    // Does the From_Ruby instantiation work with Arg?
    if constexpr (std::is_constructible_v<From_Ruby<T>, Arg*>)
    {
      return From_Ruby<T>(&this->methodInfo_->arg(I));
    }
    else
    {
      return From_Ruby<T>();
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  To_Ruby<typename NativeFunction<From_Ruby_T, Function_T, IsMethod>::Return_T> NativeFunction<From_Ruby_T, Function_T, IsMethod>::createToRuby()
  {
    // Does the From_Ruby instantiation work with ReturnInfo?
    if constexpr (std::is_constructible_v<To_Ruby<Return_T>, Return*>)
    {
      return To_Ruby<Return_T>(&this->methodInfo_->returnInfo);
    }
    else
    {
      return To_Ruby<Return_T>();
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  template<std::size_t... I>
  typename NativeFunction<From_Ruby_T, Function_T, IsMethod>::From_Ruby_Args_Ts NativeFunction<From_Ruby_T, Function_T, IsMethod>::createFromRuby(std::index_sequence<I...>& indices)
  {
    return std::make_tuple(createFromRuby<remove_cv_recursive_t<typename std::tuple_element<I, Arg_Ts>::type>, I>()...);
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  std::vector<VALUE> NativeFunction<From_Ruby_T, Function_T, IsMethod>::getRubyValues(int argc, VALUE* argv)
  {
    // Setup a tuple for the leading rb_scan_args arguments
    std::string scanFormat = this->methodInfo_->formatString();
    std::tuple<int, VALUE*, const char*> rbScanArgs = std::forward_as_tuple(argc, argv, scanFormat.c_str());

    // Create a vector to store the VALUEs that will be returned by rb_scan_args
    std::vector<VALUE> rbScanValues(std::tuple_size_v<Arg_Ts>, Qnil);

    // Convert the vector to an array so it can be concatenated to a tuple. As importantly
    // fill it with pointers to rbScanValues
    std::array<VALUE*, std::tuple_size_v<Arg_Ts>> rbScanValuePointers;
    std::transform(rbScanValues.begin(), rbScanValues.end(), rbScanValuePointers.begin(),
      [](VALUE& value)
      {
        return &value;
      });

    // Combine the tuples and call rb_scan_args
    std::apply(rb_scan_args, std::tuple_cat(rbScanArgs, rbScanValuePointers));

    return rbScanValues;
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  template<std::size_t... I>
  typename NativeFunction<From_Ruby_T, Function_T, IsMethod>::Arg_Ts NativeFunction<From_Ruby_T, Function_T, IsMethod>::getNativeValues(std::vector<VALUE>& values,
     std::index_sequence<I...>& indices)
  {
    // Convert each Ruby value to its native value by calling the appropriate fromRuby instance.
    // Note that for fundamental types From_Ruby<Arg_Ts> will keep a copy of the native value
    // so it can be passed by reference or pointer to a native function.
    return std::forward_as_tuple(std::get<I>(this->fromRubys_).convert(values[I])...);
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  typename NativeFunction<From_Ruby_T, Function_T, IsMethod>::Class_T NativeFunction<From_Ruby_T, Function_T, IsMethod>::getReceiver(VALUE self)
  {
    // There is no self parameter
    if constexpr (std::is_same_v<Class_T, std::nullptr_t>)
    {
      return nullptr;
    }
    // Self parameter is a Ruby VALUE so no conversion is needed
    else if constexpr (std::is_same_v<Class_T, VALUE>)
    {
      return self;
    }
    /* This case happens when a class wrapped by Rice is calling a method
       defined on an ancestor class. For example, the std::map size method
       is defined on _Tree not map. Rice needs to know the actual type
       that was wrapped so it can correctly extract the C++ object from 
       the Ruby object. */
    else if constexpr (!std::is_same_v<intrinsic_type<Class_T>, From_Ruby_T> && 
                        std::is_base_of_v<intrinsic_type<Class_T>, From_Ruby_T>)
    {
      From_Ruby_T* instance = From_Ruby<From_Ruby_T*>().convert(self);
      return dynamic_cast<Class_T>(instance);
    }
    // Self parameter could be derived from Object or it is an C++ instance and
    // needs to be unwrapped from Ruby
    else
    {
      return From_Ruby<Class_T>().convert(self);
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  VALUE NativeFunction<From_Ruby_T, Function_T, IsMethod>::invokeNativeFunction(const Arg_Ts& nativeArgs)
  {
    if constexpr (std::is_void_v<Return_T>)
    {
      std::apply(this->function_, nativeArgs);
      return Qnil;
    }
    else
    {
      // Call the native method and get the result
      Return_T nativeResult = std::apply(this->function_, nativeArgs);
      
      // Return the result
      return this->toRuby_.convert(nativeResult);
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  VALUE NativeFunction<From_Ruby_T, Function_T, IsMethod>::invokeNativeMethod(VALUE self, const Arg_Ts& nativeArgs)
  {
    Class_T receiver = this->getReceiver(self);
    auto selfAndNativeArgs = std::tuple_cat(std::forward_as_tuple(receiver), nativeArgs);

    if constexpr (std::is_void_v<Return_T>)
    {
      std::apply(this->function_, selfAndNativeArgs);
      return Qnil;
    }
    else
    {
      Return_T nativeResult = (Return_T)std::apply(this->function_, selfAndNativeArgs);

      // Special handling if the method returns self. If so we do not want
      // to create a new Ruby wrapper object and instead return self.
      if constexpr (std::is_same_v<intrinsic_type<Return_T>, intrinsic_type<Class_T>>)
      {
        if constexpr (std::is_pointer_v<Return_T> && std::is_pointer_v<Class_T>)
        {
          if (nativeResult == receiver)
            return self;
        }
        else if constexpr (std::is_pointer_v<Return_T> && std::is_reference_v<Class_T>)
        {
          if (nativeResult == &receiver)
            return self;
        }
        else if constexpr (std::is_reference_v<Return_T> && std::is_pointer_v<Class_T>)
        {
          if (&nativeResult == receiver)
            return self;
        }
        else if constexpr (std::is_reference_v<Return_T> && std::is_reference_v<Class_T>)
        {
          if (&nativeResult == &receiver)
            return self;
        }
      }

      return this->toRuby_.convert(nativeResult);
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  void NativeFunction<From_Ruby_T, Function_T, IsMethod>::checkKeepAlive(VALUE self, VALUE returnValue, std::vector<VALUE>& rubyValues)
  {
    // Check function arguments
    Wrapper* selfWrapper = getWrapper(self);
    for (const Arg& arg : (*this->methodInfo_))
    {
      if (arg.isKeepAlive())
      {
        selfWrapper->addKeepAlive(rubyValues[arg.position]);
      }
    }

    // Check return value
    if (this->methodInfo_->returnInfo.isKeepAlive())
    {
      Wrapper* returnWrapper = getWrapper(returnValue);
      returnWrapper->addKeepAlive(self);
    }
  }

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  VALUE NativeFunction<From_Ruby_T, Function_T, IsMethod>::operator()(int argc, VALUE* argv, VALUE self)
  {
    // Get the ruby values
    std::vector<VALUE> rubyValues = this->getRubyValues(argc, argv);

    auto indices = std::make_index_sequence<std::tuple_size_v<Arg_Ts>>{};

    // Convert the Ruby values to native values
    Arg_Ts nativeValues = this->getNativeValues(rubyValues, indices);

    // Now call the native method
    VALUE result = Qnil;
    if constexpr (std::is_same_v<Class_T, std::nullptr_t>)
    {
      result = this->invokeNativeFunction(nativeValues);
    }
    else
    {
      result = this->invokeNativeMethod(self, nativeValues);
    }

    // Check if any function arguments or return values need to have their lifetimes tied to the receiver
    this->checkKeepAlive(self, result, rubyValues);

    return result;
  }
}
