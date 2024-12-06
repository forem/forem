#ifndef Rice__hpp_
#define Rice__hpp_

// Traits

// =========   ruby.hpp   =========

/*! \file
 * \brief Hacks for addressing incompatibilities between various Ruby
 * versions.
 */

#include <cmath>

#include <ruby.h>

// ruby.h has a few defines that conflict with Visual Studio's STL
#if defined(_MSC_VER)
#undef write
#undef read
#undef bind
#endif

// And some c library conflicts
#undef isnan
#undef snprintf
#undef vsnprintf

//! A function that takes a VALUE as a parameter and returns a VALUE.
// TODO: Casting from a C++ function to an extern "C" function won't
// work on all platforms.  I'm not sure what to do about this.
extern "C" typedef VALUE (*RUBY_VALUE_FUNC)(VALUE);

// Fix Ruby RUBY_METHOD_FUNC from macro to typedef
#if defined(RUBY_METHOD_FUNC)
# undef RUBY_METHOD_FUNC
  extern "C" typedef VALUE (*RUBY_METHOD_FUNC)(ANYARGS);
#endif



// =========   rice_traits.hpp   =========

#include <ostream>
#include <string>
#include <type_traits>
#include <vector>

namespace Rice
{
  namespace detail
  {
    // Get the base_type of T - without pointer, reference, const or volatile
    template<typename T>
    using intrinsic_type = typename std::remove_cv_t<std::remove_reference_t<std::remove_pointer_t<T>>>;

    // Recursively remove const/volatile
    template<typename T>
    struct remove_cv_recursive
    {
      using type = T;
    };

    template<typename T>
    struct remove_cv_recursive<T const volatile>
    {
      using type = typename remove_cv_recursive<T>::type;
    };

    template<typename T>
    struct remove_cv_recursive<T volatile>
    {
      using type = typename remove_cv_recursive<T>::type;
    };

    template<typename T>
    struct remove_cv_recursive<T const>
    {
      using type = typename remove_cv_recursive<T>::type;
    };

    template<typename T>
    struct remove_cv_recursive<T&>
    {
      using type = typename remove_cv_recursive<T>::type&;
    };

   /* template<typename T>
    struct remove_cv_recursive<T&&>
    {
      using type = typename remove_cv_recursive<T>::type&&;
    };*/

    template<typename T>
    struct remove_cv_recursive<T*>
    {
      using type = typename remove_cv_recursive<T>::type*;
    };

    template<typename T>
    using remove_cv_recursive_t = typename remove_cv_recursive<T>::type;

    // Does the Type work with ostreams? This is used to implement #to_s
    template<typename T, typename = void>
    struct is_ostreamable : std::false_type {};

    template<typename T>
    struct is_ostreamable<T, std::void_t<decltype(std::declval<std::ostream&>() << std::declval<T>())>> : std::true_type {};

    template<typename T>
    constexpr bool is_ostreamable_v = is_ostreamable<T>::value;

    // Is the type comparable?
    template<typename T, typename SFINAE = void>
    struct is_comparable : std::false_type {};

    template<typename T>
    struct is_comparable<T, std::void_t<decltype(std::declval<T>() == std::declval<T>())>> : std::true_type {};

    template<typename T>
    constexpr bool is_comparable_v = is_comparable<T>::value;

    template <typename U, typename V>
    struct is_comparable<std::pair<U, V>>
    {
      static const bool value = is_comparable_v<U> && is_comparable_v<V>;
    };

    template <typename T>
    struct is_comparable<std::vector<T>>
    {
      static const bool value = is_comparable_v<T>;
    };

    // -- Tuple Helpers ---
    template<typename T>
    struct tuple_shift;

    template<typename T, typename...Arg_Ts>
    struct tuple_shift<std::tuple<T, Arg_Ts...>>
    {
      using type = std::tuple<Arg_Ts...>;
    };
     
    template<template<typename, typename...> typename T, typename...Arg_Ts>
    struct tuple_map;

    template<template<typename, typename...> typename T, typename...Arg_Ts>
    struct tuple_map<T, std::tuple<Arg_Ts...>>
    {
      using type = std::tuple<T<remove_cv_recursive_t<Arg_Ts>>...>;
    };
  } // detail
} // Rice


// =========   function_traits.hpp   =========

#include <tuple>

namespace Rice::detail
{
  // Base class
  template<typename Function_T>
  struct function_traits;

  template<typename Return_T, typename Class_T, typename...Arg_Ts>
  struct function_traits<Return_T(Class_T, Arg_Ts...)>
    {
    using arg_types = std::tuple<Arg_Ts...>;

    static constexpr std::size_t arity = sizeof...(Arg_Ts);

    template<std::size_t N>
    using nth_arg = typename std::tuple_element<N, arg_types>::type;

    using return_type = Return_T;
    using class_type = Class_T;
  };

  // Functors and lambdas with operator()
  template<typename Function_T>
  struct function_traits : public function_traits<decltype(&Function_T::operator())>
  {
  private:
    using functor_t = function_traits<decltype(&Function_T::operator())>;

  public:
    using arg_types = typename functor_t::arg_types;
    static constexpr std::size_t arity = functor_t::arity - 1;
    using class_type = std::nullptr_t;
  };

  // C functions and static member functions passed by pointer
  template<typename Return_T, typename ...Arg_Ts>
  struct function_traits<Return_T(*)(Arg_Ts...)> : public function_traits<Return_T(std::nullptr_t, Arg_Ts...)>
  {
  };
  
  // C functions passed by pointer that take one or more defined parameter than a variable 
  // number of parameters (the second ...)
  template<typename Return_T, typename ...Arg_Ts>
  struct function_traits<Return_T(*)(Arg_Ts..., ...)> : public function_traits<Return_T(std::nullptr_t, Arg_Ts...)>
  {
  };

  // C Functions or static member functions passed by reference
  template<typename Return_T, typename ...Arg_Ts>
  struct function_traits<Return_T(&)(Arg_Ts...)> : public function_traits<Return_T(std::nullptr_t, Arg_Ts...)>
  {
  };

  // Member Functions on C++ classes
  template<typename Return_T, typename Class_T, typename...Arg_Ts>
  struct function_traits<Return_T(Class_T::*)(Arg_Ts...)> : public function_traits<Return_T(Class_T*, Arg_Ts...)>
  {
  };

  // const member Functions on C++ classes
  template<typename Return_T, typename Class_T, typename...Arg_Ts>
  struct function_traits<Return_T(Class_T::*)(Arg_Ts...) const> : public function_traits<Return_T(Class_T*, Arg_Ts...)>
  {
  };

  // noexcept member Functions on C++ classes
  template<typename Return_T, typename Class_T, typename...Arg_Ts>
  struct function_traits<Return_T(Class_T::*)(Arg_Ts...) noexcept> : public function_traits<Return_T(Class_T*, Arg_Ts...)>
  {
  };


  // const noexcept member Functions on C++ classes
  template<typename Return_T, typename Class_T, typename...Arg_Ts>
  struct function_traits<Return_T(Class_T::*)(Arg_Ts...) const noexcept> : public function_traits<Return_T(Class_T*, Arg_Ts...)>
  {
  };

  /*// Functors and lambdas
  template<class Function_T>
  struct function_traits<Function_T&> : public function_traits<Function_T>
  {
  };

  template<class Function_T>
  struct function_traits<Function_T&&> : public function_traits<Function_T>
  {
  };*/
}

// =========   method_traits.hpp   =========

#include <tuple>

namespace Rice::detail
{
  // Declare struct
  template<typename Function_T, bool IsMethod, typename = void>
  struct method_traits;

  // Functions that do not have a self parameter:
  //   doSomething(int a)
  template<typename Function_T, bool IsMethod>
  struct method_traits<Function_T, IsMethod, std::enable_if_t<!IsMethod>>
  {
    using Return_T = typename function_traits<Function_T>::return_type;
    using Class_T = std::nullptr_t;
    using Arg_Ts = typename function_traits<Function_T>::arg_types;
    static constexpr std::size_t arity = std::tuple_size_v<Arg_Ts>;
  };

  /* Functions that have a self parameter and thus we treat them as free standing
    "methods" versus member functions. 
    
       doSomething(VALUE self, int a) */
  template<typename Function_T, bool IsMethod>
  struct method_traits<Function_T, IsMethod, std::enable_if_t<IsMethod && std::is_same_v<typename function_traits<Function_T>::class_type, std::nullptr_t>>>
  {
    using Return_T = typename function_traits<Function_T>::return_type;
    using Class_T = typename function_traits<Function_T>::template nth_arg<0>;
    using Arg_Ts = typename tuple_shift<typename function_traits<Function_T>::arg_types>::type;
    static constexpr std::size_t arity = std::tuple_size_v<Arg_Ts>;
  };

  // Member functions that have an implied self parameter of an object instance
  //   foo.doSomething(int a)
  template<typename Function_T, bool IsMethod>
  struct method_traits<Function_T, IsMethod, std::enable_if_t<IsMethod && !std::is_same_v<typename function_traits<Function_T>::class_type, std::nullptr_t>>>
  {
    using Return_T = typename function_traits<Function_T>::return_type;
    using Class_T = typename function_traits<Function_T>::class_type;
    using Arg_Ts = typename function_traits<Function_T>::arg_types;
    static constexpr std::size_t arity = std::tuple_size_v<Arg_Ts>;
  };
}

// =========   attribute_traits.hpp   =========

#include <tuple>

namespace Rice::detail
{
  // Base class
  template<typename Attribute_T>
  struct attribute_traits;

  template<typename Attr_T>
  struct attribute_traits<Attr_T*>
  {
    using attr_type = Attr_T;
    using class_type = std::nullptr_t;
  };

  template<typename Attr_T, typename Class_T>
  struct attribute_traits<Attr_T Class_T::*> 
  {
    using attr_type = Attr_T;
    using class_type = Class_T;
  };
}

// Code for C++ to call Ruby

// =========   Exception_defn.hpp   =========

#include <stdexcept>

namespace Rice
{
  //! A placeholder for Ruby exceptions.
  /*! You can use this to safely throw a Ruby exception using C++ syntax:
   *  \code
   *    VALUE foo(VALUE self) {
   *      RUBY_TRY {
   *        throw Rice::Exception(rb_eMyException, "uh oh!");
   *      RUBY_CATCH
   *    }
   *  \endcode
   */
  class Exception
    : public std::exception
  {
  public:
    //! Construct a Exception with a Ruby exception instance
    explicit Exception(VALUE exception);

    //! Construct a Exception with printf-style formatting.
    /*! \param exc either an exception object or a class that inherits
     *  from Exception.
     *  \param fmt a printf-style format string
     *  \param ... the arguments to the format string.
     */
    template <typename... Arg_Ts>
    Exception(const Exception& other, char const* fmt, Arg_Ts&&...args);

    //! Construct a Exception with printf-style formatting.
    /*! \param exc either an exception object or a class that inherits
     *  from Exception.
     *  \param fmt a printf-style format string
     *  \param ... the arguments to the format string.
     */
    template <typename... Arg_Ts>
    Exception(const VALUE exceptionType, char const* fmt, Arg_Ts&&...args);

    //! Destructor
    virtual ~Exception() noexcept = default;

    //! Get message as a char const *.
    /*! If message is a non-string object, then this function will attempt
     *  to throw an exception (which it can't do because of the no-throw
     *  specification).
     *  \return the underlying C pointer of the underlying message object.
     */
    virtual char const* what() const noexcept override;

    //! Returns the Ruby exception class
    VALUE class_of() const;

    //! Returns an instance of a Ruby exception
    VALUE value() const;

  private:
    // TODO: Do we need to tell the Ruby gc about an exception instance?
    mutable VALUE exception_ = Qnil;
    mutable std::string message_;
  };
} // namespace Rice


// =========   Jump_Tag.hpp   =========

namespace Rice
{
  //! A placeholder for Ruby longjmp data.
  /*! When a Ruby exception is caught, the tag used for the longjmp is stored in
   *  a Jump_Tag, then later passed to rb_jump_tag() when there is no more
   *  C++ code to pass over.
   */
  struct Jump_Tag
  {
    //! Construct a Jump_Tag with tag t.
    Jump_Tag(int t) : tag(t) {}

    //! The tag being held.
    int tag;
  };
} // namespace Rice


// =========   RubyFunction.hpp   =========


namespace Rice::detail
{
  /* This is functor class that wraps calls to a Ruby C API method. It is needed because
     rb_protect only supports calling methods that take one argument. Thus 
     we invoke rb_protect telling it to invoke Ruby_Function::call with an 
     instance of a Ruby_Function. That instance then in turn calls the original
     Ruby method passing along its required arguments. */

  template<typename Function_T, typename...Arg_Ts>
  class RubyFunction
  {
  public:
    using Return_T = typename function_traits<Function_T>::return_type;

  public:
    RubyFunction(Function_T func, const Arg_Ts&... args);
    Return_T operator()();

  private:
    Function_T func_;
    std::tuple<Arg_Ts...> args_;
  };

  template<typename Function_T, typename ...Arg_Ts>
  auto protect(Function_T func, Arg_Ts...args);
}

// ---------   RubyFunction.ipp   ---------

#include <any>

namespace Rice::detail
{
  template<typename Function_T, typename...Arg_Ts>
  inline RubyFunction<Function_T, Arg_Ts...>::RubyFunction(Function_T func, const Arg_Ts&... args)
    : func_(func), args_(std::forward_as_tuple(args...))
  {
  }

  template<typename Function_T, typename...Arg_Ts>
  inline typename RubyFunction<Function_T, Arg_Ts...>::Return_T RubyFunction<Function_T, Arg_Ts...>::operator()()
  {
    const int TAG_RAISE = 0x6; // From Ruby header files
    int state = 0;

    // Setup a thread local variable to capture the result of the Ruby function call.
    // We use thread_local because the lambda has to be captureless so it can
    // be converted to a function pointer callable by C.
    // The thread local variable avoids having to cast the result to VALUE and then 
    // back again to Return_T. The problem with that is the translation is not lossless
    // in some cases - for example a double with value of -1.0 does not roundrip.
    // 
    thread_local std::any result;

    // Callback that will invoke the Ruby function
    using Functor_T = RubyFunction<Function_T, Arg_Ts...>;
    auto callback = [](VALUE value) -> VALUE
    {
      Functor_T* functor = (Functor_T*)value;

      if constexpr (std::is_same_v<Return_T, void>)
      {
        std::apply(functor->func_, functor->args_);
      }
      else
      {
        result = std::apply(functor->func_, functor->args_);
      }

      return Qnil;
    };

    // Now call rb_protect which will invoke the callback lambda above
    rb_protect(callback, (VALUE)this, &state);

    // Did anything go wrong?
    if (state == 0)
    {
      if constexpr (!std::is_same_v<Return_T, void>)
      {
        return std::any_cast<Return_T>(result);
      }
    }
    else
    {
      VALUE err = rb_errinfo();
      if (state == TAG_RAISE && RB_TEST(err))
      {
        rb_set_errinfo(Qnil);
        throw Rice::Exception(err);
      }
      else
      {
        throw Jump_Tag(state);
      }
    }
  }
    
  // Create a functor for calling a Ruby function and define some aliases for readability.
  template<typename Function_T, typename ...Arg_Ts>
  auto protect(Function_T func, Arg_Ts...args)
  {
    auto rubyFunction = RubyFunction<Function_T, Arg_Ts...>(func, std::forward<Arg_Ts>(args)...);
    return rubyFunction();
  }
}

// Code for Ruby to call C++

// =========   ExceptionHandler.hpp   =========


// ---------   ExceptionHandler_defn.hpp   ---------
#ifndef Rice__detail__ExceptionHandler_defn__hpp_
#define Rice__detail__ExceptionHandler_defn__hpp_

#include <memory>

namespace Rice::detail
{
  /* An abstract class for converting C++ exceptions to ruby exceptions.  It's used
     like this:

     try
     {
     }
     catch(...)
     {
       handler->handle();
     }

   If an exception is thrown the handler will pass the exception up the
   chain, then the last handler in the chain will throw the exception
   down the chain until a lower handler can handle it, e.g.:

   try
   {
     return call_next_ExceptionHandler();
   }
   catch(MyException const & ex)
   {
     throw Rice::Exception(rb_cMyException, "%s", ex.what());
    }

    Memory management. Handlers are created by the ModuleBase constructor. When the
    module defines a new Ruby method, metadata  is stored on the Ruby klass including
    the exception handler. Since the metadata outlives the module, handlers are stored
    using std::shared_ptr. Thus the Module (or its inherited children) can be destroyed
    without corrupting the metadata references to the shared exception handler. */

  class ExceptionHandler
  {
  public:
    ExceptionHandler() = default;
    virtual ~ExceptionHandler() = default;

    // Don't allow copying or assignment
    ExceptionHandler(const ExceptionHandler& other) = delete;
    ExceptionHandler& operator=(const ExceptionHandler& other) = delete;

    virtual VALUE handle() const = 0;
  };

  // The default exception handler just rethrows the exception.  If there
  // are other handlers in the chain, they will try to handle the rethrown
  // exception.
  class DefaultExceptionHandler : public ExceptionHandler
  {
  public:
    virtual VALUE handle() const override;
  };

  // An exception handler that takes a functor as an argument.  The
  // functor should throw a Rice::Exception to handle the exception.  If
  // the functor does not handle the exception, the exception will be
  // re-thrown.
  template <typename Exception_T, typename Functor_T>
  class CustomExceptionHandler : public ExceptionHandler
  {
  public:
    CustomExceptionHandler(Functor_T handler, std::shared_ptr<ExceptionHandler> nextHandler);
    virtual VALUE handle() const override;

  private:
    Functor_T handler_;
    std::shared_ptr<ExceptionHandler> nextHandler_;
  };
}
#endif // Rice__detail__ExceptionHandler_defn__hpp_
// ---------   ExceptionHandler.ipp   ---------
namespace Rice::detail
{
  inline VALUE Rice::detail::DefaultExceptionHandler::handle() const
  {
    throw;
  }

  template <typename Exception_T, typename Functor_T>
  inline Rice::detail::CustomExceptionHandler<Exception_T, Functor_T>::
    CustomExceptionHandler(Functor_T handler, std::shared_ptr<ExceptionHandler> nextHandler)
    : handler_(handler), nextHandler_(nextHandler)
  {
  }

  template <typename Exception_T, typename Functor_T>
  inline VALUE Rice::detail::CustomExceptionHandler<Exception_T, Functor_T>::handle() const
  {
    try
    {
      return this->nextHandler_->handle();
    }
    catch (Exception_T const& ex)
    {
      handler_(ex);
      throw;
    }
  }
}


// =========   Type.hpp   =========

#include <string>
#include <typeinfo>

namespace Rice::detail
{
  template<typename T>
  struct Type
  {
    static bool verify();
  };

  // Return the name of a type
  std::string typeName(const std::type_info& typeInfo);
  std::string makeClassName(const std::type_info& typeInfo);

  template<typename T>
  void verifyType();

  template<typename Tuple_T>
  void verifyTypes();
}


// ---------   Type.ipp   ---------

#include <iosfwd>
#include <iterator>
#include <numeric>
#include <regex>
#include <sstream>
#include <tuple>

#ifdef __GNUC__
#include <cxxabi.h>
#include <cstdlib>
#include <cstring>
#endif

namespace Rice::detail
{
  template<>
  struct Type<void>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<typename T>
  void verifyType()
  {
    Type<intrinsic_type<T>>::verify();
  }

  template<typename Tuple_T, size_t...Is>
  void verifyTypesImpl()
  {
    (verifyType<typename std::tuple_element<Is, Tuple_T>::type>(), ...);
  }

  template<typename Tuple_T>
  void verifyTypes()
  {
    if constexpr (std::tuple_size<Tuple_T>::value > 0)
    {
      verifyTypesImpl<Tuple_T, std::tuple_size<Tuple_T>::value - 1>();
    }
  }

  inline std::string demangle(char const* mangled_name)
  {
#ifdef __GNUC__
    struct Helper
    {
      Helper(
        char const* mangled_name)
        : name_(0)
      {
        int status = 0;
        name_ = abi::__cxa_demangle(mangled_name, 0, 0, &status);
      }

      ~Helper()
      {
        std::free(name_);
      }

      char* name_;

    private:
      Helper(Helper const&);
      void operator=(Helper const&);
    };

    Helper helper(mangled_name);
    if (helper.name_)
    {
      return helper.name_;
    }
    else
    {
      return mangled_name;
    }
#else
    return mangled_name;
#endif
  }

  inline std::string typeName(const std::type_info& typeInfo)
  {
    return demangle(typeInfo.name());
  }

  inline std::string makeClassName(const std::type_info& typeInfo)
  {
    std::string base = demangle(typeInfo.name());

    // Remove class keyword
    auto classRegex = std::regex("class +");
    base = std::regex_replace(base, classRegex, "");

    // Remove struct keyword
    auto structRegex = std::regex("struct +");
    base = std::regex_replace(base, structRegex, "");

    // Remove std::__[^:]*::
    auto stdClangRegex = std::regex("std::__[^:]+::");
    base = std::regex_replace(base, stdClangRegex, "");
      
    // Remove std::
    auto stdRegex = std::regex("std::");
    base = std::regex_replace(base, stdRegex, "");

    // Replace > > 
    auto trailingAngleBracketSpaceRegex = std::regex(" >");
    base = std::regex_replace(base, trailingAngleBracketSpaceRegex, ">");

    // Replace < and >
    auto angleBracketRegex = std::regex("<|>");
    base = std::regex_replace(base, angleBracketRegex, "__");

    // Replace ,
    auto commaRegex = std::regex(", *");
    base = std::regex_replace(base, commaRegex, "_");

    // Now create a vector of strings split on whitespace
    std::istringstream stream(base);
    std::vector<std::string> words{ std::istream_iterator<std::string>{stream},
                                    std::istream_iterator<std::string>{} };

    std::string result = std::accumulate(words.begin(), words.end(), std::string(),
      [](const std::string& memo, const std::string& word) -> std::string
      {
        std::string capitalized = word;
        capitalized[0] = toupper(capitalized[0]);
        return memo + capitalized;
      });

    return result;
  }
}


// =========   TypeRegistry.hpp   =========

#include <optional>
#include <string>
#include <typeindex>
#include <typeinfo>
#include <unordered_map>


/* The type registry keeps track of all C++ types wrapped by Rice. When a native function returns 
   an instance of a class/struct we look up its type to verity that it has been registered. 
   
   We have to do this to support C++ inheritance. If a C++ function returns a pointer/reference
   to an Abstract class, the actual returned object will be a Child class. However, all we know
   from the C++ method signature is that it is an Absract class - thus the need for a registry.*/

namespace Rice::detail
{
  class TypeRegistry
  {
  public:
    template <typename T>
    void add(VALUE klass, rb_data_type_t* rbType);

    template <typename T>
    void remove();

    template <typename T>
    bool isDefined();

    template <typename T>
    bool verifyDefined();
      
    template <typename T>
    std::pair<VALUE, rb_data_type_t*> figureType(const T& object);

  private:
    std::optional<std::pair<VALUE, rb_data_type_t*>> lookup(const std::type_info& typeInfo);
    std::unordered_map<std::type_index, std::pair<VALUE, rb_data_type_t*>> registry_{};
  };
}


// ---------   TypeRegistry.ipp   ---------
#include <stdexcept>


namespace Rice::detail
{
  template <typename T>
  inline void TypeRegistry::add(VALUE klass, rb_data_type_t* rbType)
  {
    std::type_index key(typeid(T));
    registry_[key] = std::pair(klass, rbType);
  }

  template <typename T>
  inline void TypeRegistry::remove()
  {
    std::type_index key(typeid(T));
    registry_.erase(key);
  }

  template <typename T>
  inline bool TypeRegistry::isDefined()
  {
    std::type_index key(typeid(T));
    auto iter = registry_.find(key);
    return iter != registry_.end();
  }

  template <typename T>
  inline bool TypeRegistry::verifyDefined()
  {
    if (!isDefined<T>())
    {
      std::string message = "Type is not defined with Rice: " + detail::typeName(typeid(T));
      throw std::invalid_argument(message);
    }
    return true;
  }

  inline std::optional<std::pair<VALUE, rb_data_type_t*>> TypeRegistry::lookup(const std::type_info& typeInfo)
  {
    std::type_index key(typeInfo);
    auto iter = registry_.find(key);

    if (iter == registry_.end())
    {
      return std::nullopt;
    }
    else
    {
      return iter->second;
    }
  }

  template <typename T>
  inline std::pair<VALUE, rb_data_type_t*> TypeRegistry::figureType(const T& object)
  {
    // First check and see if the actual type of the object is registered
    std::optional<std::pair<VALUE, rb_data_type_t*>> result = lookup(typeid(object));

    if (result)
    {
      return result.value();
    }

    // If not, then we are willing to accept an ancestor class specified by T. This is needed
    // to support Directors. Classes inherited from Directors are never actually registered
    // with Rice - and what we really want it to return the C++ class they inherit from.
    result = lookup(typeid(T));
    if (result)
    {
      return result.value();
    }

    // Give up!
    std::string message = "Type " + typeName(typeid(object)) + " is not registered";
    throw std::runtime_error(message.c_str());
  }
}

// =========   InstanceRegistry.hpp   =========

#include <map>

namespace Rice::detail
{
  class InstanceRegistry
  {
  public:
    template <typename T>
    VALUE lookup(T& cppInstance);

    template <typename T>
    VALUE lookup(T* cppInstance);

    void add(void* cppInstance, VALUE rubyInstance);
    void remove(void* cppInstance);
    void clear();

  public:
    bool isEnabled = false;

  private:
    VALUE lookup(void* cppInstance);
    std::map<void*, VALUE> objectMap_;
  };
} // namespace Rice::detail


// ---------   InstanceRegistry.ipp   ---------
#include <memory>

namespace Rice::detail
{
  template <typename T>
  inline VALUE InstanceRegistry::lookup(T& cppInstance)
  {
    return this->lookup((void*)&cppInstance);
  }

  template <typename T>
  inline VALUE InstanceRegistry::lookup(T* cppInstance)
  {
    return this->lookup((void*)cppInstance);
  }

  inline VALUE InstanceRegistry::lookup(void* cppInstance)
  {
    if (!this->isEnabled)
      return Qnil;

    auto it = this->objectMap_.find(cppInstance);
    if (it != this->objectMap_.end())
    {
      return it->second;
    }
    else
    {
      return Qnil;
    }
  }

  inline void InstanceRegistry::add(void* cppInstance, VALUE rubyInstance)
  {
    if (this->isEnabled)
    {
      this->objectMap_[cppInstance] = rubyInstance;
    }
  }

  inline void InstanceRegistry::remove(void* cppInstance)
  {
    this->objectMap_.erase(cppInstance);
  }

  inline void InstanceRegistry::clear()
  {
    this->objectMap_.clear();
  }
} // namespace



// =========   HandlerRegistry.hpp   =========


namespace Rice::detail
{
  class HandlerRegistry
  {
  public:
    //! Define an exception handler.
    /*! Whenever an exception of type Exception_T is thrown from a
     *  function defined on this class, the supplied functor will be called to
     *  translate the exception into a ruby exception.
     *  \param Exception_T a template parameter indicating the type of
     *  exception to be translated.
     *  \param functor a functor to be called to translate the exception
     *  into a ruby exception.  This functor should re-throw the exception
     *  as an Exception.
     *  Example:
     *  \code
     *    Class rb_cFoo;
     *
     *    void translate_my_exception(MyException const& ex)
     *    {
     *       throw Rice::Exception(rb_eRuntimeError, ex.what_without_backtrace());
     *    }
     *
     *    extern "C"
     *    void Init_MyExtension()
     *    {
     *      rb_cFoo = define_class("Foo");
     *      register_handler<MyException>(translate_my_exception);
     *    }
     *  \endcode
     */
    template<typename Exception_T, typename Functor_T>
    HandlerRegistry& add(Functor_T functor);

    std::shared_ptr<detail::ExceptionHandler> handler() const;

  private:
    mutable std::shared_ptr<detail::ExceptionHandler> handler_ = std::make_shared<Rice::detail::DefaultExceptionHandler>();

  };
} // namespace Rice::detail


// ---------   HandlerRegistry.ipp   ---------
#include <memory>

namespace Rice::detail
{
  template<typename Exception_T, typename Functor_T>
  inline HandlerRegistry& HandlerRegistry::add(Functor_T functor)
  {
    // Create a new exception handler and pass ownership of the current handler to it (they
    // get chained together). Then take ownership of the new handler.
    this->handler_ = std::make_shared<detail::CustomExceptionHandler<Exception_T, Functor_T>>(
      functor, std::move(this->handler_));

    return *this;
  }

  inline std::shared_ptr<detail::ExceptionHandler> HandlerRegistry::handler() const
  {
    return this->handler_;
  }
} // namespace



// =========   NativeRegistry.hpp   =========

#include <unordered_map>
#include <any>


namespace Rice::detail
{
  class NativeRegistry
  {
  public:
    // Add a new native callable object keyed by Ruby class and method_id
    void add(VALUE klass, ID method_id, std::any callable);

    // Returns the Rice data for the currently active Ruby method
    template <typename Return_T>
    Return_T lookup();

    template <typename Return_T>
    Return_T lookup(VALUE klass, ID method_id);

  private:
    size_t key(VALUE klass, ID method_id);
    std::unordered_map<size_t, std::any> natives_ = {};
  };
} 

// ---------   NativeRegistry.ipp   ---------

// Ruby 2.7 now includes a similarly named macro that uses templates to
// pick the right overload for the underlying function. That doesn't work
// for our cases because we are using this method dynamically and get a
// compilation error otherwise. This removes the macro and lets us fall
// back to the C-API underneath again.
#undef rb_define_method_id


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


// =========   Registries.hpp   =========


namespace Rice::detail
{
  class Registries
  {
  public:
    static Registries instance;

  public:
    HandlerRegistry handlers;
    InstanceRegistry instances;
    NativeRegistry natives;
    TypeRegistry types;
  };
}


// ---------   Registries.ipp   ---------
namespace Rice::detail
{
  //Initialize static variables here.
  inline Registries Registries::instance;

  // TODO - Big hack here but this code is dependent on internals
  template<typename T>
  bool Type<T>::verify()
  {
    // Use intrinsic_type so that we don't have to define specializations
    // for pointers, references, const, etc.
    using Intrinsic_T = intrinsic_type<T>;

    if constexpr (std::is_fundamental_v<Intrinsic_T>)
    {
      return true;
    }
    else
    {
      return Registries::instance.types.verifyDefined<Intrinsic_T>();
    }
  }
}


// =========   cpp_protect.hpp   =========

#include <regex>
#include <filesystem>
#include <stdexcept>


namespace Rice::detail
{
  template <typename Callable_T>
  auto cpp_protect(Callable_T&& func)
  {
    try
    {
      return func();
    }
    catch (...)
    {
      try
      {
        detail::Registries::instance.handlers.handler()->handle();
      }
      catch (::Rice::Exception const& ex)
      {
        rb_exc_raise(ex.value());
      }
      catch (::Rice::Jump_Tag const& ex)
      {
        rb_jump_tag(ex.tag);
      }
      catch (std::bad_alloc const& ex)
      {
        /* This won't work quite right if the rb_exc_new2 fails; not
           much we can do about that, since Ruby doesn't give us access
           to a pre-allocated NoMemoryError object */
        rb_exc_raise(rb_exc_new2(rb_eNoMemError, ex.what()));
      }
      catch (std::domain_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eFloatDomainError, ex.what()));
      }
      catch (std::invalid_argument const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eArgError, ex.what()));
      }
      catch (std::filesystem::filesystem_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eIOError, ex.what()));
      }
      catch (std::length_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRuntimeError, ex.what()));
      }
      catch (std::out_of_range const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRangeError, ex.what()));
      }
      catch (std::overflow_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRangeError, ex.what()));
      }
      catch (std::range_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRangeError, ex.what()));
      }
      catch (std::regex_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRegexpError, ex.what()));
      }
      catch (std::system_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eSystemCallError, ex.what()));
      }
      catch (std::underflow_error const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRangeError, ex.what()));
      }
      catch (std::exception const& ex)
      {
        rb_exc_raise(rb_exc_new2(rb_eRuntimeError, ex.what()));
      }
      catch (...)
      {
        rb_exc_raise(rb_exc_new2(rb_eRuntimeError, "Unknown C++ exception thrown"));
      }
      throw std::runtime_error("Should never get here - just making compilers happy");
    }
  }
}

// =========   Wrapper.hpp   =========


namespace Rice
{
namespace detail
{

class Wrapper
{
public:
  virtual ~Wrapper() = default;
  virtual void* get() = 0;

  void ruby_mark();
  void addKeepAlive(VALUE value);

private:
  // We use a vector for speed and memory locality versus a set which does
  // not scale well when getting to tens of thousands of objects (not expecting
  // that to happen...but just in case)
  std::vector<VALUE> keepAlive_;
};

template <typename T, typename Wrapper_T = void>
VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T& data, bool isOwner);

template <typename T, typename Wrapper_T = void>
VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T* data, bool isOwner);

template <typename T>
T* unwrap(VALUE value, rb_data_type_t* rb_type);

Wrapper* getWrapper(VALUE value, rb_data_type_t* rb_type);

template <typename T>
void replace(VALUE value, rb_data_type_t* rb_type, T* data, bool isOwner);

Wrapper* getWrapper(VALUE value);

} // namespace detail
} // namespace Rice


// ---------   Wrapper.ipp   ---------
#include <memory>

namespace Rice::detail
{
  inline void Wrapper::ruby_mark()
  {
    for (VALUE value : this->keepAlive_)
    {
      rb_gc_mark(value);
    }
  }

  inline void Wrapper::addKeepAlive(VALUE value)
  {
    this->keepAlive_.push_back(value);
  }

  template <typename T>
  class WrapperValue : public Wrapper
  {
  public:
    WrapperValue(T& data): data_(std::move(data))
    {
    }

    ~WrapperValue()
    {
      Registries::instance.instances.remove(this->get());
    }

    void* get() override
    {
      return (void*)&this->data_;
    }

  private:
    T data_;
  };

  template <typename T>
  class WrapperReference : public Wrapper
  {
  public:
    WrapperReference(T& data): data_(data)
    {
    }

    ~WrapperReference()
    {
      Registries::instance.instances.remove(this->get());
    }

    void* get() override
    {
      return (void*)&this->data_;
    }

  private:
    T& data_;
  };

  template <typename T>
  class WrapperPointer : public Wrapper
  {
  public:
    WrapperPointer(T* data, bool isOwner) : data_(data), isOwner_(isOwner)
    {
    }

    ~WrapperPointer()
    {
      Registries::instance.instances.remove(this->get());

      if (this->isOwner_)
      {
        delete this->data_;
      }
    }

    void* get() override
    {
      return (void*)this->data_;
    }

  private:
    T* data_ = nullptr;
    bool isOwner_ = false;
  };

  // ---- Helper Functions -------
  template <typename T, typename Wrapper_T>
  inline VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T& data, bool isOwner)
  {
    VALUE result = Registries::instance.instances.lookup(&data);

    if (result != Qnil)
      return result;

    Wrapper* wrapper = nullptr;

    if constexpr (!std::is_void_v<Wrapper_T>)
    {
      wrapper = new Wrapper_T(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else if (isOwner)
    {
      wrapper = new WrapperValue<T>(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else
    {
      wrapper = new WrapperReference<T>(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }

    Registries::instance.instances.add(wrapper->get(), result);

    return result;
  };

  template <typename T, typename Wrapper_T>
  inline VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T* data, bool isOwner)
  {
    VALUE result = Registries::instance.instances.lookup(data);

    if (result != Qnil)
      return result;

    Wrapper* wrapper = nullptr;

    if constexpr (!std::is_void_v<Wrapper_T>)
    {
      wrapper = new Wrapper_T(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else
    {
      wrapper = new WrapperPointer<T>(data, isOwner);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }

    Registries::instance.instances.add(wrapper->get(), result);
    return result;
  };

  template <typename T>
  inline T* unwrap(VALUE value, rb_data_type_t* rb_type)
  {
    Wrapper* wrapper = getWrapper(value, rb_type);

    if (wrapper == nullptr)
    {
      std::string message = "Wrapped C++ object is nil. Did you override " + 
                            std::string(detail::protect(rb_obj_classname, value)) + 
                            "#initialize and forget to call super?";

      throw std::runtime_error(message);
    }

    return static_cast<T*>(wrapper->get());
  }
    
  inline Wrapper* getWrapper(VALUE value, rb_data_type_t* rb_type)
  {
    Wrapper* wrapper = nullptr;
    TypedData_Get_Struct(value, Wrapper, rb_type, wrapper);
    return wrapper;
  }

  template <typename T>
  inline void replace(VALUE value, rb_data_type_t* rb_type, T* data, bool isOwner)
  {
    WrapperPointer<T>* wrapper = nullptr;
    TypedData_Get_Struct(value, WrapperPointer<T>, rb_type, wrapper);
    if (wrapper)
    {
      Registries::instance.instances.remove(wrapper->get());
      delete wrapper;
    }

    wrapper = new WrapperPointer<T>(data, isOwner);
    RTYPEDDATA_DATA(value) = wrapper;

    Registries::instance.instances.add(data, value);
  }

  inline Wrapper* getWrapper(VALUE value)
  {
    // Turn off spurious warning on g++ 12
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#endif
    return static_cast<Wrapper*>(RTYPEDDATA_DATA(value));
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
  }
} // namespace



// =========   Return.hpp   =========

#include <any>

namespace Rice
{
  //! Helper for defining Return argument of a method

  class Return
  {
  public:
    //! Specifies Ruby should take ownership of the returned value
    Return& takeOwnership();

    //! Does Ruby own the returned value?
    bool isOwner();

    //! Specifies the returned value is a Ruby value
    Return& setValue();

    //! Is the returned value a Ruby value?
    bool isValue() const;

    //! Tell the returned object to keep alive the receving object
    Return& keepAlive();

    //! Is the returned value being kept alive?
    bool isKeepAlive() const;

  private:
    bool isKeepAlive_ = false;
    bool isOwner_ = false;
    bool isValue_ = false;
  };
} // Rice


// ---------   Return.ipp   ---------
#include <any>
#include <string>

namespace Rice
{
  inline Return& Return::takeOwnership()
  {
    this->isOwner_ = true;
    return *this;
  }

  inline bool Return::isOwner()
  {
    return this->isOwner_;
  }

  inline Return& Return::setValue()
  {
    this->isValue_ = true;
    return *this;
  }

  inline bool Return::isValue() const
  {
    return this->isValue_;
  }

  inline Return& Return::keepAlive()
  {
    this->isKeepAlive_ = true;
    return *this;
  }

  inline bool Return::isKeepAlive() const
  {
    return this->isKeepAlive_;
  }
}  // Rice


// =========   Arg.hpp   =========

#include <any>

namespace Rice
{
  //! Helper for defining default arguments of a method
  /*! This class exposes the ability to define the default values of a
   *  wrapped method. Inspired by how Boost.Python handles keyword and
   *  default arguments, the syntax is simple:
   *
   *  \code
   *    define_method(
   *      "method",
   *      &method,
   *      Arg("arg1"), Arg("arg2") = 3, Arg("arg3") = true
   *    );
   *  \endcode
   *
   *  which means "for method &method, it takes 3 arguments
   *  [arg1, arg2, arg3]. Of these arguments, arg2's default is 3
   *  and arg3's default is true.
   *
   *  It may be required to explicitly cast the type of the default
   *  value to prevent compilation errors.
   */
  class Arg
  {
  public:
    //! Initialize a new Arg with the name of the argument
    /*! We require the name of the argument because 1) it makes code
     *  easier to read and 2) hopefully Ruby gets keyword arguments
     *  in the future and this means Rice will be ready for it.
     */
    Arg(std::string name);

    //! Set the default value for this Arg
    /*! Set the default value for this argument.
     *  If this isn't called on this Arg, then this
     *  Arg is required in the method call.
     *
     *  \param val the value to store as default
     */
    template<typename Arg_Type>
    Arg& operator=(Arg_Type val);

    //! Check if this Arg has a default value associated with it
    bool hasDefaultValue() const;

    //! Return a reference to the default value associated with this Arg
    /*! \return the type saved to this Arg
     */
    template<typename Arg_Type>
    Arg_Type& defaultValue();

    //! Tell the receiving object to keep this argument alive
    //! until the receiving object is freed.
    Arg& keepAlive();
    
    //! Returns if the argument should be kept alive
    bool isKeepAlive() const;

    //! Specifies if the argument should be treated as a value
    Arg& setValue();

    //! Returns if the argument should be treated as a value
    bool isValue() const;

  public:
    const std::string name;
    int32_t position = -1;

  private:
    //! Our saved default value
    std::any defaultValue_;
    bool isValue_ = false;
    bool isKeepAlive_ = false;
  };
} // Rice


// ---------   Arg.ipp   ---------
namespace Rice
{
  inline Arg::Arg(std::string name) : name(name)
  {
  }

  template<typename Arg_Type>
  inline Arg& Arg::operator=(Arg_Type val)
  {
    this->defaultValue_ = val;
    return *this;
  }

  //! Check if this Arg has a default value associated with it
  inline bool Arg::hasDefaultValue() const
  {
    return this->defaultValue_.has_value();
  }

  //! Return a reference to the default value associated with this Arg
  /*! \return the type saved to this Arg
    */
  template<typename Arg_Type>
  inline Arg_Type& Arg::defaultValue()
  {
    return std::any_cast<Arg_Type&>(this->defaultValue_);
  }

  inline Arg& Arg::keepAlive()
  {
    this->isKeepAlive_ = true;
    return *this;
  }

  inline bool Arg::isKeepAlive() const
  {
    return this->isKeepAlive_;
  }

  inline Arg& Arg::setValue()
  {
    isValue_ = true;
    return *this;
  }

  inline bool Arg::isValue() const
  {
    return isValue_;
  }
} // Rice

// =========   MethodInfo.hpp   =========

#include <vector>

namespace Rice
{
  class MethodInfo
  {
  public:
    template <typename...Arg_Ts>
    MethodInfo(size_t argCount, const Arg_Ts&...args);

    /**
      * Get the rb_scan_args format string for this
      * list of arguments.
      */
    std::string formatString();

    /**
      * Add a defined Arg to this list of Arguments
      */
    void addArg(const Arg& arg);

    Arg& arg(size_t pos);

    // Iterator support
    std::vector<Arg>::iterator begin();
    std::vector<Arg>::iterator end();

    Return returnInfo;

  private:
    template <typename Arg_T>
    void processArg(const Arg_T& arg);

    std::vector<Arg> args_;
  };
}

// ---------   MethodInfo.ipp   ---------
#include <sstream>

namespace Rice
{
  template <typename...Arg_Ts>
  inline MethodInfo::MethodInfo(size_t argCount, const Arg_Ts&...args)
  {
    // Process the passed in arguments
    (this->processArg(args), ...);

    // Fill in any missing arguments
    for (size_t i = this->args_.size(); i < argCount; i++)
    {
      Arg arg("arg_" + std::to_string(i));
      this->addArg(arg);
    }

    // TODO - so hacky but update the Arg positions
    for (uint32_t i = 0; i < this->args_.size(); i++)
    {
      this->args_[i].position = i;
    }
  }

  template <typename Arg_T>
  inline void MethodInfo::processArg(const Arg_T& arg)
  {
    if constexpr (std::is_same_v<Arg_T, Arg>)
    {
      this->addArg(arg);
    }
    else
    {
      this->returnInfo = arg;
    }
  }

  inline void MethodInfo::addArg(const Arg& arg)
  {
    this->args_.push_back(arg);
  }

  inline std::string MethodInfo::formatString()
  {
    size_t required = 0;
    size_t optional = 0;

    for (const Arg& arg : this->args_)
    {
      if (arg.hasDefaultValue())
      {
        optional++;
      }
      else
      {
        required++;
      }
    }

    return std::to_string(required) + std::to_string(optional);
  }

  inline Arg& MethodInfo::arg(size_t pos)
  {
    return args_[pos];
  }

  inline std::vector<Arg>::iterator MethodInfo::begin()
  {
    return this->args_.begin();
  }

  inline std::vector<Arg>::iterator MethodInfo::end()
  {
    return this->args_.end();
  }
}


// =========   from_ruby.hpp   =========


// ---------   from_ruby_defn.hpp   ---------
#ifndef Rice__detail__from_ruby_defn__hpp_
#define Rice__detail__from_ruby_defn__hpp_

#include <type_traits>


namespace Rice::detail
{
  //! Convert a Ruby object to C++.
  /*! If the Ruby object can be converted to an immediate value, returns a
   *  copy of the Ruby object.  If the Ruby object is holding a C++
   *  object and the type specified is a pointer to that type, returns a
   *  pointer to that object.
   *
   *  Conversions from ruby to a pointer type are automatically generated
   *  when a type is bound using Data_Type.  If no conversion exists an
   *  exception is thrown.
   *
   *  \param T the C++ type to which to convert.
   *  \param x the Ruby object to convert.
   *  \return a C++ representation of the Ruby object.
   *
   *  Example:
   *  \code
   *    Object x = INT2NUM(42);
   *    std::cout << From_Ruby<int>::convert(x);
   *
   *    Data_Object<Foo> foo(new Foo);
   *    std::cout << *From_Ruby<Foo *>(foo) << std::endl;
   *  \endcode
   */

  template <typename T>
  class From_Ruby;
}

#endif // Rice__detail__From_Ruby2_defn__hpp_

// ---------   from_ruby.ipp   ---------
#ifndef Rice__detail__from_ruby__ipp_
#define Rice__detail__from_ruby__ipp_

#include <optional>
#include <stdexcept>

/* This file implements conversions from Ruby to native values fo fundamental types 
   such as bool, int, float, etc. It also includes conversions for chars and strings */
namespace Rice::detail
{
  // ===========  short  ============
  template<>
  class From_Ruby<short>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<short>();
      }
      else
      {
        return protect(rb_num2short_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<short&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<short>();
      }
      else
      {
        this->converted_ = protect(rb_num2short_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    short converted_ = 0;
  };

  template<>
  class From_Ruby<short*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2short_inline, value);
        return &this->converted_;
      }
    }

  private:
    short converted_ = 0;
  };

  // ===========  int  ============
  template<>
  class From_Ruby<int>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<int>();
      }
      else
      {
        return (int)protect(rb_num2long_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<int&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<int>();
      }
      else
      {
        this->converted_ = (int)protect(rb_num2long_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    int converted_ = 0;
  };

  template<>
  class From_Ruby<int*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (int)protect(rb_num2long_inline, value);
        return &this->converted_;
      }
    }

  private:
    int converted_;
  };

  // ===========  long  ============
  template<>
  class From_Ruby<long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long>();
      }
      else
      {
        return protect(rb_num2long_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long>();
      }
      else
      {
        this->converted_ = protect(rb_num2long_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    long converted_ = 0;
  };

  template<>
  class From_Ruby<long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2long_inline, value);
        return &this->converted_;
      }
    }

  private:
    long converted_ = 0;
  };

  // ===========  long long  ============
  template<>
  class From_Ruby<long long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long long>();
      }
      else
      {
        return protect(rb_num2ll_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<long long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ll_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    long long converted_ = 0;
  };

  template<>
  class From_Ruby<long long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ll_inline, value);
        return &this->converted_;
      }
    }

  private:
    long long converted_ = 0;
  };

  // ===========  unsigned short  ============
  template<>
  class From_Ruby<unsigned short>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned short>();
      }
      else
      {
        return protect(rb_num2ushort, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned short&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned short>();
      }
      else
      {
        this->converted_ = protect(rb_num2ushort, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned short converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned short*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ushort, value);
        return &this->converted_;
      }
    }

  private:
    unsigned short converted_ = 0;
  };

  // ===========  unsigned int  ============
  template<>
  class From_Ruby<unsigned int>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned int>();
      }
      else
      {
        return (unsigned int)protect(rb_num2ulong_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned int&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned int>();
      }
      else
      {
        this->converted_ = (unsigned int)protect(rb_num2ulong_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned int converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned int*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (unsigned int)protect(rb_num2ulong_inline, value);
        return &this->converted_;
      }
    }

  private:
    unsigned int converted_ = 0;
  };

  // ===========  unsigned long  ============
  template<>
  class From_Ruby<unsigned long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long convert(VALUE value)
    {
      if (this->arg_ && this->arg_->isValue())
      {
        return (unsigned long)value;
      }
      else if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long>();
      }
      else
      {
        return protect(rb_num2ulong_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ulong_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned long converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ulong_inline, value);
        return &this->converted_;
      }
    }

  private:
    unsigned long converted_ = 0;
  };

  // ===========  unsigned long long  ============
  template<>
  class From_Ruby<unsigned long long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long convert(VALUE value)
    {
      if (this->arg_ && this->arg_->isValue())
      {
        return value;
      }
      else if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long long>();
      }
      else
      {
        return protect(rb_num2ull, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned long long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ull, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned long long converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned long long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ull, value);
        return &this->converted_;
      }
    }

  private:
    unsigned long long converted_ = 0;
  };

  // ===========  bool  ============
  template<>
  class From_Ruby<bool>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
            ruby_type == RUBY_T_FALSE ||
            ruby_type == RUBY_T_NIL;
    }

    bool convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<bool>();
      }
      else
      {
        return RTEST(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<bool&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
             ruby_type == RUBY_T_FALSE ||
             ruby_type == RUBY_T_NIL;
    }

    bool& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<bool>();
      }
      else
      {
        this->converted_ = RTEST(value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    bool converted_ = false;
  };

  template<>
  class From_Ruby<bool*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
             ruby_type == RUBY_T_FALSE ||
             ruby_type == RUBY_T_NIL;
    }

    bool* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = RTEST(value);
        return &this->converted_;
      }
    }

  private:
    bool converted_ = false;
  };

  // ===========  char  ============
  template<typename T>
  inline T charFromRuby(VALUE value)
  {
    switch (rb_type(value))
    {
      case T_STRING:
      {
        if (RSTRING_LEN(value) == 1)
        {
          return RSTRING_PTR(value)[0];
        }
        else
        {
          throw std::invalid_argument("from_ruby<char>: string must have length 1");
        }
        break;
      }
      case T_FIXNUM:
      {
        return From_Ruby<long>().convert(value) & 0xff;
        break;
      }
      default:
      {
        throw Exception(rb_eTypeError, "wrong argument type %s (expected % s)",
          detail::protect(rb_obj_classname, value), "char type");
      }
    }
  }
  
  template<>
  class From_Ruby<char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<char>();
      }
      else
      {
        return charFromRuby<char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<char&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<char>();
      }
      else
      {
        this->converted_ = charFromRuby<char>(value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    char converted_ = 0;
  };

  template<>
  class From_Ruby<char*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        detail::protect(rb_check_type, value, (int)T_STRING);
        return RSTRING_PTR(value);
      }
    }
  };
  
  // This is mostly for testing. NativeFunction removes const before calling From_Ruby
  template<>
  class From_Ruby<char const*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char const* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        detail::protect(rb_check_type, value, (int)T_STRING);
        return RSTRING_PTR(value);
      }
    }
  };

  // ===========  unsinged char  ============
  template<>
  class From_Ruby<unsigned char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    unsigned char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned char>();
      }
      else
      {
        return charFromRuby<unsigned char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  // ===========  signed char  ============
  template<>
  class From_Ruby<signed char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    signed char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<signed char>();
      }
      else
      {
        return charFromRuby<signed char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  // ===========  double  ============
  template<>
  class From_Ruby<double>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<double>();
      }
      else
      {
        return protect(rb_num2dbl, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<double&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<double>();
      }
      else
      {
        this->converted_ = protect(rb_num2dbl, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    double converted_;
  };

  template<>
  class From_Ruby<double*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2dbl, value);
        return &this->converted_;
      }
    }

  private:
    double converted_;
  };

  // ===========  float  ============
  template<>
  class From_Ruby<float>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<float>();
      }
      else
      {
        return (float)protect(rb_num2dbl, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<float&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<float>();
      }
      else
      {
        this->converted_ = (float)protect(rb_num2dbl, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    float converted_;
  };

  template<>
  class From_Ruby<float*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (float)protect(rb_num2dbl, value);
        return &this->converted_;
      }
    }

  private:
    float converted_;
  };
}
#endif // Rice__detail__from_ruby__ipp_



// =========   to_ruby.hpp   =========


// ---------   to_ruby_defn.hpp   ---------
#ifndef Rice__detail__to_ruby_defn__hpp_
#define Rice__detail__to_ruby_defn__hpp_


namespace Rice
{
  namespace detail
  {
    //! Convert a C++ object to Ruby.
    /*! If x is a pointer, wraps the pointee as a Ruby object.  If x is an
     *  Object, returns x.
     *
     *  If no conversion exists a compile-time error is generated.
     *
     *  \param x the object to convert.
     *  \return a Ruby representation of the C++ object.
     *
     *  Example:
     *  \code
     *    rb_p(to_ruby(42));
     *
     *    Foo * p_foo = new Foo();
     *    rb_p(to_ruby(p_foo));
     *  \endcode
     */
    template <typename T>
    class To_Ruby;
   
    // Helper template function that let's users avoid having to specify the template type - its deduced
    template <typename T>
    VALUE to_ruby(T&& x)
    {
      using Unqualified_T = remove_cv_recursive_t<T>;
      return To_Ruby<Unqualified_T>().convert(std::forward<T>(x));
    }

    // Helper template function that let's users avoid having to specify the template type - its deduced
    template <typename T>
    VALUE to_ruby(T* x)
    {
      using Unqualified_T = remove_cv_recursive_t<T>;
      return To_Ruby<Unqualified_T*>().convert(x);
    }
  } // detail
} // Rice

#endif // Rice__detail__to_ruby_defn__hpp_

// ---------   to_ruby.ipp   ---------

namespace Rice
{
  namespace detail
  {
    template<>
    class To_Ruby<void>
    {
    public:
      VALUE convert(void const*)
      {
        return Qnil;
      }
    };

    template<>
    class To_Ruby<std::nullptr_t>
    {
    public:
      VALUE convert(std::nullptr_t const)
      {
        return Qnil;
      }
    };

    template<>
    class To_Ruby<short>
    {
    public:
      VALUE convert(short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<short&>
    {
    public:
      VALUE convert(short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<int>
    {
    public:
      VALUE convert(int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<int&>
    {
    public:
      VALUE convert(int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<long>
    {
    public:
      VALUE convert(long const& x)
      {
        return protect(rb_long2num_inline, x);
      }
    };

    template<>
    class To_Ruby<long&>
    {
    public:
      VALUE convert(long const& x)
      {
        return protect(rb_long2num_inline, x);
      }
    };

    template<>
    class To_Ruby<long long>
    {
    public:
      VALUE convert(long long const& x)
      {
        return protect(rb_ll2inum, x);
      }
    };

    template<>
    class To_Ruby<long long&>
    {
    public:
      VALUE convert(long long const& x)
      {
        return protect(rb_ll2inum, x);
      }
    };

    template<>
    class To_Ruby<unsigned short>
    {
    public:
      VALUE convert(unsigned short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned short&>
    {
    public:
      VALUE convert(unsigned short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned int>
    {
    public:
      VALUE convert(unsigned int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned int&>
    {
    public:
      VALUE convert(unsigned int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned long>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ulong2num_inline, x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long&>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ulong2num_inline, x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long long>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ull2inum, (unsigned long long)x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long long&>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ull2inum, (unsigned long long)x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<float>
    {
    public:
      VALUE convert(float const& x)
      {
        return protect(rb_float_new, (double)x);
      }
    };

    template<>
    class To_Ruby<float&>
    {
    public:
      VALUE convert(float const& x)
      {
        return protect(rb_float_new, (double)x);
      }
    };

    template<>
    class To_Ruby<double>
    {
    public:
      VALUE convert(double const& x)
      {
        return protect(rb_float_new, x);
      }
    };

    template<>
    class To_Ruby<double&>
    {
    public:
      VALUE convert(double const& x)
      {
        return protect(rb_float_new, x);
      }
    };

    template<>
    class To_Ruby<bool>
    {
    public:
      VALUE convert(bool const& x)
      {
        return x ? Qtrue : Qfalse;
      }
    };

    template<>
    class To_Ruby<bool&>
    {
    public:
      VALUE convert(bool const& x)
      {
        return x ? Qtrue : Qfalse;
      }
    };

    template<>
    class To_Ruby<char>
    {
    public:
      VALUE convert(char const& x)
      {
        return To_Ruby<int>().convert(x);
      }
    };

    template<>
    class To_Ruby<char&>
    {
    public:
      VALUE convert(char const& x)
      {
        return To_Ruby<int>().convert(x);
      }
    };

    template<>
    class To_Ruby<unsigned char>
    {
    public:
      VALUE convert(unsigned char const& x)
      {
        return To_Ruby<unsigned int>().convert(x);
      }
    };

    template<>
    class To_Ruby<unsigned char&>
    {
    public:
      VALUE convert(unsigned char const& x)
      {
        return To_Ruby<unsigned int>().convert(x);
      }
    };

    template<>
    class To_Ruby<signed char>
    {
    public:
      VALUE convert(signed char const& x)
      {
        return To_Ruby<signed int>().convert(x);
      }
    };

    template<>
    class To_Ruby<signed char&>
    {
    public:
      VALUE convert(signed char const& x)
      {
        return To_Ruby<signed int>().convert(x);
      }
    };

    template<>
    class To_Ruby<char*>
    {
    public:
      VALUE convert(char const* x)
      {
        if (strlen(x) > 0 && x[0] == ':')
        {
          size_t symbolLength = strlen(x) - 1;
          char* symbol = new char[symbolLength];
          strncpy(symbol, x + 1, symbolLength);
          ID id = protect(rb_intern2, symbol, (long)symbolLength);
          delete[] symbol;
          return protect(rb_id2sym, id);
        }
        else
        {
          return protect(rb_str_new2, x);
        }
      }
    };

    template<int N>
    class To_Ruby<char[N]>
    {
    public:
      VALUE convert(char const x[])
      {
        if (N > 0 && x[0] == ':')
        {
          // N count includes a NULL character at the end of the string
          constexpr size_t symbolLength = N - 1;
          char symbol[symbolLength];
          strncpy(symbol, x + 1, symbolLength);
          ID id = protect(rb_intern, symbol);
          return protect(rb_id2sym, id);
        }
        else
        {
          return protect(rb_str_new2, x);
        }
      }
    };
  }
}


// =========   Identifier.hpp   =========

#include <string>

namespace Rice
{
  class Symbol;

  //! A wrapper for the ID type
  /*! An ID is ruby's internal representation of a Symbol object.
   */
  class Identifier
  {
  public:
    //! Construct a new Identifier from an ID.
    Identifier(ID id);

    //! Construct a new Identifier from a Symbol.
    Identifier(Symbol const& symbol);

    //! Construct a new Identifier from a c string.
    Identifier(char const* s);

    //! Construct a new Identifier from a string.
    Identifier(std::string const string);

    //! Return a string representation of the Identifier.
    char const* c_str() const;

    //! Return a string representation of the Identifier.
    std::string str() const;

    //! Return the underlying ID
    ID id() const { return id_; }

    //! Return the underlying ID
    operator ID() const { return id_; }

    //! Return the ID as a Symbol
    VALUE to_sym() const;

  private:
    ID id_;
  };
} // namespace Rice


// ---------   Identifier.ipp   ---------
namespace Rice
{
  inline Identifier::Identifier(ID id) : id_(id)
  {
  }

  inline Identifier::Identifier(char const* s) : id_(rb_intern(s))
  {
  }

  inline Identifier::Identifier(std::string const s) : id_(rb_intern(s.c_str()))
  {
  }

  inline char const* Identifier::c_str() const
  {
    return detail::protect(rb_id2name, id_);
  }

  inline std::string Identifier::str() const
  {
    return c_str();
  }

  inline VALUE Identifier::to_sym() const
  {
    return ID2SYM(id_);
  }
}

// =========   Exception.ipp   =========


namespace Rice
{
  inline Exception::Exception(VALUE exception) : exception_(exception)
  {
  }

  template <typename... Arg_Ts>
  inline Exception::Exception(const Exception& other, char const* fmt, Arg_Ts&&...args)
    : Exception(other.class_of(), fmt, std::forward<Arg_Ts>(args)...)
  {
  }

  template <typename... Arg_Ts>
  inline Exception::Exception(const VALUE exceptionClass, char const* fmt, Arg_Ts&&...args)
  {
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-security"
#endif

    size_t size = std::snprintf(nullptr, 0, fmt, std::forward<Arg_Ts>(args)...);
    this->message_ = std::string(size, '\0');

    // size+1 avoids truncating the string. Otherwise snprintf writes n - 1 characters
    // to allow space for null character but we don't need that since std::string
    // will add a null character internally at n + 1
    std::snprintf(&this->message_[0], size + 1, fmt, std::forward<Arg_Ts>(args)...);

#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif

    // Now create the Ruby exception
    this->exception_ = detail::protect(rb_exc_new2, exceptionClass, this->message_.c_str());
  }

  inline char const* Exception::what() const noexcept
  {
    if (this->message_.empty())
    {
      // This isn't protected because if it fails then either we could eat the exception
      // (not good) or crash the program (better)
      VALUE rubyMessage = rb_funcall(this->exception_, rb_intern("message"), 0);
      this->message_ = std::string(RSTRING_PTR(rubyMessage), RSTRING_LEN(rubyMessage));
    }
    return this->message_.c_str();
  }

  inline VALUE Exception::class_of() const
  {
    return detail::protect(rb_class_of, this->exception_);
  }

  inline VALUE Exception::value() const
  {
    return this->exception_;
  }
}

// =========   NativeAttribute.hpp   =========


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


// ---------   NativeAttribute.ipp   ---------
#include <array>
#include <algorithm>


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


// =========   NativeFunction.hpp   =========


namespace Rice::detail
{
  //! The NativeFunction class calls C++ functions/methods/lambdas on behalf of Ruby
  /*! The NativeFunction class is an intermediate between Ruby and C++. Every method
   *  defined in Rice is associated with a NativeFuntion instance that is stored in
   *  a unordered_map maintained by the MethodData class. The key is the Ruby class
   *  and method.
   * 
   *  When Ruby calls into C++ it invokes the static NativeFunction.call method. This
   *  method then looks up the NativeFunction instance and calls its ->() operator.
   *
   *  The instance then converts each of the arguments passed from Ruby into their
   *  C++ equivalents. It then retrieves the C++ object (if there is one, Ruby could
   *  be calling a free standing method or lambda). Then it calls the C++ method
   *  and gets back the result. If there is a result (so not void), it is converted
   *  from a C++ object to a Ruby object and returned back to Ruby.
   * 
   *  This class make heavy use of C++ Template metaprogramming to determine
   *  the types and parameters a method takes. It then uses that information
   *  to perform type conversion Ruby to C++.
   *   
   *  @tparam From_Ruby_T - The type of C++ class wrapped by Ruby. Note
   *    this may be different than the Class of Function_T. For example, 
   *    std::map has a size() method but that is actually implemented on 
   *    an ancestor class _Tree. Thus From_Ruby_T is std::map but 
   *    Function_T::Class_T is _Tree. This typename must be specified
   *    by the calling code.
   *  @tparam Function_T - A template that represents the C++ function
   *    to call. This typename is automatically deduced by the compiler.
   *  @tparam IsMethod - A boolean specifying whether the function has
   *    a self parameter or not. Rice differentiates these two cases by
   *    calling them methods (self) or functions (no self).
   */

  template<typename From_Ruby_T, typename Function_T, bool IsMethod>
  class NativeFunction
  {
  public:
    using NativeFunction_T = NativeFunction<From_Ruby_T, Function_T, IsMethod>;

    // We remove const to avoid an explosion of To_Ruby specializations and Ruby doesn't
    // have the concept of constants anyways
    using Return_T = remove_cv_recursive_t<typename function_traits<Function_T>::return_type>;
    using Class_T = typename method_traits<Function_T, IsMethod>::Class_T;
    using Arg_Ts = typename method_traits<Function_T, IsMethod>::Arg_Ts;
    using From_Ruby_Args_Ts = typename tuple_map<From_Ruby, Arg_Ts>::type;

    // Register function with Ruby
    static void define(VALUE klass, std::string method_name, Function_T function, MethodInfo* methodInfo);

    // Static member function that Ruby calls
    static VALUE call(int argc, VALUE* argv, VALUE self);

  public:
    // Disallow creating/copying/moving
    NativeFunction() = delete;
    NativeFunction(const NativeFunction_T&) = delete;
    NativeFunction(NativeFunction_T&&) = delete;
    void operator=(const NativeFunction_T&) = delete;
    void operator=(NativeFunction_T&&) = delete;

    // Invokes the wrapped function
    VALUE operator()(int argc, VALUE* argv, VALUE self);

  protected:
    NativeFunction(VALUE klass, std::string method_name, Function_T function, MethodInfo* methodInfo);

  private:
    template<typename T, std::size_t I>
    From_Ruby<T> createFromRuby();
      
    // Create NativeArgs which are used to convert values from Ruby to C++
    template<std::size_t...I>
    From_Ruby_Args_Ts createFromRuby(std::index_sequence<I...>& indices);

    To_Ruby<Return_T> createToRuby();
      
    // Convert Ruby argv pointer to Ruby values
    std::vector<VALUE> getRubyValues(int argc, VALUE* argv);

    // Convert Ruby values to C++ values
    template<typename std::size_t...I>
    Arg_Ts getNativeValues(std::vector<VALUE>& values, std::index_sequence<I...>& indices);

    // Figure out what self is
    Class_T getReceiver(VALUE self);

    // Do we need to keep alive any arguments?
    void checkKeepAlive(VALUE self, VALUE returnValue, std::vector<VALUE>& rubyValues);

    // Call the underlying C++ function
    VALUE invokeNativeFunction(const Arg_Ts& nativeArgs);
    VALUE invokeNativeMethod(VALUE self, const Arg_Ts& nativeArgs);

  private:
    VALUE klass_;
    std::string method_name_;
    Function_T function_;
    From_Ruby_Args_Ts fromRubys_;
    To_Ruby<Return_T> toRuby_;
    std::unique_ptr<MethodInfo> methodInfo_;
  };
}

// ---------   NativeFunction.ipp   ---------
#include <array>
#include <algorithm>
#include <stdexcept>


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


// =========   NativeIterator.hpp   =========
#ifndef Rice_NativeIterator__hpp_
#define Rice_NativeIterator__hpp_


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

// ---------   NativeIterator.ipp   ---------
#include <iterator>
#include <functional>
#include <type_traits>


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
#endif // Rice_NativeIterator__hpp_
// =========   HandlerRegistration.hpp   =========


namespace Rice
{
  // Register exception handler
  template<typename Exception_T, typename Functor_T>
  detail::HandlerRegistry register_handler(Functor_T functor)
  {
    return detail::Registries::instance.handlers.add<Exception_T, Functor_T>(std::forward<Functor_T>(functor));
  }
}

// C++ classes for using the Ruby API

// =========   Object.hpp   =========


// ---------   Object_defn.hpp   ---------
#ifndef Rice__Object_defn__hpp_
#define Rice__Object_defn__hpp_

/*! \file Object.hpp
 */


#include <iosfwd>
#include <vector>

namespace Rice
{
  class Class;
  class String;
  class Array;

  //! The base class for all Objects
  /*! Perhaps the name "Object" is a misnomer, because this class really
   *  holds an object reference, not an object.
   */
  class Object
  {
  public:
    //! Encapsulate an existing ruby object.
    Object(VALUE value = Qnil) : value_(value) {}

    //! Destructor
    virtual ~Object();

    // Enable copying
    Object(const Object& other) = default;
    Object& operator=(const Object& other) = default;

    // Enable moving
    Object(Object&& other);
    Object& operator=(Object&& other);

    //! Returns false if the object is nil or false; returns true
    //! otherwise.
    // Having this conversion also prevents accidental conversion to
    // undesired integral types (e.g. long or int) by making the
    // conversion ambiguous.
    bool test() const { return RTEST(value_); }

    //! Returns false if the object is nil or false; returns true
    //! otherwise.
    operator bool() const { return test(); }

    //! Returns true if the object is nil, false otherwise.
    bool is_nil() const { return NIL_P(value_); }

    //! Implicit conversion to VALUE.
    operator VALUE() const { return value_; }

    //! Explicitly get the encapsulated VALUE.
    // Returns a const ref so that Address_Registration_Guard can access
    // the address where the VALUE is stored
    VALUE const volatile& value() const { return value_; }

    //! Get the class of an object.
    /*! \return the object's Class.
     */
    Class class_of() const;

    //! Compare this object to another object.
    /*! Gets the result of self <=> other and returns the result.  The
     *  result will be less than zero if self < other, greater than zero
     *  if self > other, and equal to zero if self == other.
     */
    int compare(Object const& other) const;

    //! Return a string representation of an object.
    /*! \return the result of calling to_s on the object.  A String is not
     *  returned, because it is not possible to return an instance of a
     *  derived class.
     */
    String to_s() const;

    //! Return the name of an object's class.
    String class_name() const;

    //! Inspect the object.
    /*! \return the result of calling inspect on the object.  A String is
     *  not returned, because it is not possible to return an instance of
     *  a derived class.
     */
    String inspect() const;

    //! Freeze the object.
    void freeze();

    //! Determine if the object is frozen.
    /*! \return true if the object is frozen, false otherwise.
     */
    bool is_frozen() const;

    //! Evaluate the given string in the context of the object.
    /*! This is equivalant to calling obj.instance_eval(s) from inside the
     *  interpreter.
     *  \return the result of the expression.
     */
    Object instance_eval(String const& s);

    //! Return the type of the underlying C object.
    /*! This is equivalent to calling rb_type(obj).
     * \return the type of the underlying C object (e.g. T_DATA, T_ARRAY,
     * etc.).
     */
    int rb_type() const;

    //! Return the object's id
    VALUE object_id() const;

    //! Determine whether the object is an instance of a class/module.
    /*! \param klass a class or module.
     *  \return true if the object is an instance of the given
     *  class/module or one of its descendants.
     */
    bool is_a(Object klass) const;

    //! Determine if the objects responds to a method.
    /*! \param id the name of the method
     *  \return true if the objects responds to the method, false
     *  otherwise.
     */
    bool respond_to(Identifier id) const;

    //! Determine whether class is the object's class.
    /*! \param klass a class.
     *  \return true if the object is an instance of the given class.
     */
    bool is_instance_of(Object klass) const;

    //! Determine whether the Ruby VALUEs wrapped by this
    //! object are the same object. Maps to Object::equal?
    /*! \param other a Object.
     */
    bool is_equal(const Object& other) const;

    //! Determine whether the Ruby VALUEs wrapped by this
    //! object are equivalent. Maps to Object::eql?
    /*! \param other a Object.
     */
    bool is_eql(const Object& other) const;

    //! Set an instance variable.
    /*! \param name the name of the instance variable to set (including
     *  the leading @ sign)
     *  \param value the value of the variable, which will be converted to
     *  a Ruby type if necessary.
     */
    template<typename T>
    void iv_set(Identifier name, T const& value);

    //! Get the value of an instance variable.
    /*! \param name the name of the instance variable to get
     *  \return the value of the instance variable
     */
    Object iv_get(Identifier name) const;

    //! Get the value of an instance variable, but don't warn if it is
    //unset.
    /*! \param name the name of the instance variable to get
     *  \return the value of the instance variable
     */
    Object attr_get(Identifier name) const;

    //! Call the Ruby method specified by 'id' on object 'obj'.
    /*! Pass in arguments (arg1, arg2, ...).  The arguments will be converted to
    *  Ruby objects with to_ruby<>.
    *
    *  E.g.:
    *  \code
    *    Rice::Object obj = x.call("foo", "one", 2);
    *  \endcode
    *
    *  If a return type is specified, the return value will automatically be
    *  converted to that type as long as 'from_ruby' exists for that type.
    *
    *  E.g.:
    *  \code
    *    float ret = x.call<float>("foo", z, 42);
    *  \endcode
    */
    template<typename ...Arg_Ts>
    Object call(Identifier id, Arg_Ts... args) const;

    //! Vectorized call.
    /*! Calls the method identified by id with the list of arguments
     *  identified by args.
     *  \param id the name of the method to call
     *  \param args the arguments to the method
     *  \return the return value of the method call
     */
    Object vcall(Identifier id, Array args);

    //! Get a constant.
    /*! \param name the name of the constant to get.
     *  \return the value of the constant.
     */
    Object const_get(Identifier name) const;

    //! Determine whether a constant is defined.
    /*! \param name the name of the constant to check.
     *  \return true if the constant is defined in this module or false
     *  otherwise.
     */
    bool const_defined(Identifier name) const;

    //! Set a constant.
    /*! \param name the name of the constant to set.
      *  \param value the value of the constant.
      *  \return *this
      */
    inline Object const_set(Identifier name, Object value);

    //! Set a constant if it not already set.
    /*! \param name the name of the constant to set.
      *  \param value the value of the constant.
      *  \return *this
      */
    inline Object const_set_maybe(Identifier name, Object value);

    //! Remove a constant.
    /*! \param name the name of the constant to remove.
     */
    void remove_const(Identifier name);

  protected:
    //! Set the encapsulated value.
    void set_value(VALUE v);

  private:
    volatile VALUE value_;
  };

  std::ostream& operator<<(std::ostream& out, Object const& obj);

  bool operator==(Object const& lhs, Object const& rhs);
  bool operator!=(Object const& lhs, Object const& rhs);
  bool operator<(Object const& lhs, Object const& rhs);
  bool operator>(Object const& lhs, Object const& rhs);

  extern Object const Nil;
  extern Object const True;
  extern Object const False;
  extern Object const Undef;
} // namespace Rice

#endif // Rice__Object_defn__hpp_
// ---------   Object.ipp   ---------
#ifndef Rice__Object__ipp_
#define Rice__Object__ipp_

namespace Rice
{
  inline const Object Nil(Qnil);
  inline const Object True(Qtrue);
  inline const Object False(Qfalse);
  inline const Object Undef(Qundef);

  // Ruby auto detects VALUEs in the stack, so when an Object gets deleted make sure
  // to clean up in case it is on the stack
  inline Object::~Object()
  {
    this->value_ = Qnil;
  }

  // Move constructor
  inline Object::Object(Object&& other)
  {
    this->value_ = other.value_;
    other.value_ = Qnil;
  }

  // Move assignment
  inline Object& Object::operator=(Object&& other)
  {
    this->value_ = other.value_;
    other.value_ = Qnil;
    return *this;
  }

  template<typename ...Arg_Ts>
  inline Object Object::call(Identifier id, Arg_Ts... args) const
  {
    /* IMPORTANT - We store VALUEs in an array that is a local variable.
       That allows the Ruby garbage collector to find them when scanning
       the stack and thus mark them. If instead we use a vector, then Ruby's GC
       can't find the VALUEs and may garbage collect them before they are sent
       to the destination method resulting in a segmentation fault. This is
       easy to duplicate by setting GC.stress to true and calling a constructor
       that takes multiple values like a std::pair wrapper. */
    std::array<VALUE, sizeof...(Arg_Ts)> values = { detail::To_Ruby<detail::remove_cv_recursive_t<Arg_Ts>>().convert(args)... };
    return detail::protect(rb_funcallv_kw, value(), id.id(), (int)values.size(), (const VALUE*)values.data(), RB_PASS_CALLED_KEYWORDS);
  }

  template<typename T>
  inline void Object::iv_set(Identifier name, T const& value)
  {
    detail::protect(rb_ivar_set, this->value(), name.id(), detail::To_Ruby<T>().convert(value));
  }

  inline int Object::compare(Object const& other) const
  {
    Object result = call("<=>", other);
    return detail::From_Ruby<int>().convert(result);
  }

  inline bool Object::is_equal(const Object& other) const
  {
    VALUE result = detail::protect(rb_equal, this->value_, other.value_);
    return RB_TEST(result);
  }

  inline bool Object::is_eql(const Object& other) const
  {
    VALUE result = detail::protect(rb_eql, this->value_, other.value_);
    return RB_TEST(result);
  }

  inline void Object::freeze()
  {
    detail::protect(rb_obj_freeze, value());
  }

  inline bool Object::is_frozen() const
  {
    return RB_OBJ_FROZEN(value());
  }

  inline int Object::rb_type() const
  {
    return ::rb_type(this->value());
  }

  inline VALUE Object::object_id() const
  {
    return detail::protect(rb_obj_id, this->value());
  }

  inline bool Object::is_a(Object klass) const
  {
    VALUE result = detail::protect(rb_obj_is_kind_of, this->value(), klass.value());
    return RB_TEST(result);
  }

  inline bool Object::respond_to(Identifier id) const
  {
    return bool(rb_respond_to(this->value(), id.id()));
  }

  inline bool Object::is_instance_of(Object klass) const
  {
    VALUE result = detail::protect(rb_obj_is_instance_of, this->value(), klass.value());
    return RB_TEST(result);
  }

  inline Object Object::iv_get(Identifier name) const
  {
    return detail::protect(rb_ivar_get, this->value(), name.id());
  }

  inline Object Object::attr_get(Identifier name) const
  {
    return detail::protect(rb_attr_get, this->value(), name.id());
  }

  inline void Object::set_value(VALUE v)
  {
    value_ = v;
  }

  inline Object Object::const_get(Identifier name) const
  {
    return detail::protect(rb_const_get, this->value(), name.id());
  }

  inline bool Object::const_defined(Identifier name) const
  {
    size_t result = detail::protect(rb_const_defined, this->value(), name.id());
    return bool(result);
  }

  inline Object Object::const_set(Identifier name, Object value)
  {
    detail::protect(rb_const_set, this->value(), name.id(), value.value());
    return value;
  }

  inline Object Object::const_set_maybe(Identifier name, Object value)
  {
    if (!this->const_defined(name))
    {
      this->const_set(name, value);
    }
    return value;
  }

  inline void Object::remove_const(Identifier name)
  {
    detail::protect(rb_mod_remove_const, this->value(), name.to_sym());
  }

  inline bool operator==(Object const& lhs, Object const& rhs)
  {
    VALUE result = detail::protect(rb_equal, lhs.value(), rhs.value());
    return result == Qtrue ? true : false;
  }

  inline bool operator!=(Object const& lhs, Object const& rhs)
  {
    return !(lhs == rhs);
  }

  inline bool operator<(Object const& lhs, Object const& rhs)
  {
    Object result = lhs.call("<", rhs);
    return result.test();
  }

  inline bool operator>(Object const& lhs, Object const& rhs)
  {
    Object result = lhs.call(">", rhs);
    return result.test();
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Object>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class To_Ruby<Object>
  {
  public:
    static VALUE convert(Object const& x)
    {
      return x.value();
    }
  };

  template<>
  class To_Ruby<Object&>
  {
  public:
    static VALUE convert(Object const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<Object>
  {
  public:
    Object convert(VALUE value)
    {
      return Object(value);
    }
  };
}
#endif // Rice__Object__ipp_


// =========   Builtin_Object.hpp   =========


// ---------   Builtin_Object_defn.hpp   ---------
#ifndef Rice__Builtin_Object_defn__hpp_
#define Rice__Builtin_Object_defn__hpp_


namespace Rice
{
  //! A smartpointer-like wrapper for Ruby builtin objects.
  /*! A builtin object is one of Ruby's internal types, e.g. RArray or
   *  RString.  Every builtin type structure has a corresponding integer
   *  type number (e.g T_ARRAY for RArray or T_STRING for RString).  This
   *  class is a wrapper for those types of objects, primarily useful as a
   *  base class for other wrapper classes like Array and Hash.
   */
  template<int Builtin_Type>
  class Builtin_Object
    : public Object
  {
  public:
    //! Wrap an already allocated Ruby object.
    /*! Checks to see if the object is an object of type Builtin_Type; a
     *  C++ exception is thrown if this is not the case.
     *  \param value the object to be wrapped.
     */
    Builtin_Object(Object value);

    RObject& operator*() const; //!< Return a reference to obj_
    RObject* operator->() const; //!< Return a pointer to obj_
    RObject* get() const;       //!< Return a pointer to obj_
  };
} // namespace Rice

#endif // Rice__Builtin_Object_defn__hpp_
// ---------   Builtin_Object.ipp   ---------
#ifndef Rice__Builtin_Object__ipp_
#define Rice__Builtin_Object__ipp_

#include <algorithm>

namespace Rice
{
  namespace detail
  {
    inline VALUE check_type(Object value, int type)
    {
      detail::protect(rb_check_type, value.value(), type);
      return Qnil;
    }
  }

  template<int Builtin_Type>
  inline Builtin_Object<Builtin_Type>::Builtin_Object(Object value) : Object(value)
  {
    detail::check_type(value, Builtin_Type);
  }

  template<int Builtin_Type>
  inline RObject& Builtin_Object<Builtin_Type>::operator*() const
  {
    return *ROBJECT(this->value());
  }

  template<int Builtin_Type>
  inline RObject* Builtin_Object<Builtin_Type>::operator->() const
  {
    return ROBJECT(this->value());
  }

  template<int Builtin_Type>
  inline RObject* Builtin_Object<Builtin_Type>::get() const
  {
    return ROBJECT(this->value());
  }
} // namespace Rice

#endif // Rice__Builtin_Object__ipp_

// =========   String.hpp   =========


namespace Rice
{
  //! A Wraper for the ruby String class.
  /*! This class provides a C++-style interface to ruby's String class and
   *  its associated rb_str_* functions.
   *
   *  Example:
   *  \code
   *    String s(String::format("%s: %d", "foo", 42));
   *    std::cout << s.length() << std::endl;
   *  \endcode
   */
  class String
    : public Builtin_Object<T_STRING>
  {
  public:
    //! Construct a new string.
    String();

    //! Wrap an existing string.
    String(VALUE v);

    //! Wrap an existing string.
    String(Object v);

    //! Construct a String from an Identifier.
    String(Identifier id);

    //! Construct a String from a null-terminated C string.
    String(char const* s);

    //! Construct a String from an std::string.
    String(std::string const& s);

    //! Format a string using printf-style formatting.
    template <typename... Arg_Ts>
    static inline String format(char const* fmt, Arg_Ts&&...args);

    //! Get the length of the String.
    /*! \return the length of the string.
     */
    size_t length() const;

    //! Get the character at the given index.
    /*! \param index the desired index.
     *  \return the character at the given index.
     */
    char operator[](ptrdiff_t index) const;

    //! Return a pointer to the beginning of the underlying C string.
    char const* c_str() const;

    //! Return a copy of the string as an std::string.
    std::string str() const;

    //! Create an Identifier from the String.
    /*! Calls rb_intern to create an ID.
     *  \return an Identifier holding the ID returned from rb_intern.
     */
    Identifier intern() const;
  };
} // namespace Rice


// ---------   String.ipp   ---------
namespace Rice
{
  inline String::String() : Builtin_Object<T_STRING>(detail::protect(rb_str_new2, ""))
  {
  }

  inline String::String(VALUE v) : Builtin_Object<T_STRING>(v)
  {
  }

  inline String::String(Object v) : Builtin_Object<T_STRING>(v)
  {
  }

  inline String::String(char const* s) : Builtin_Object<T_STRING>(detail::protect(rb_str_new2, s))
  {
  }

  inline String::String(std::string const& s) : Builtin_Object<T_STRING>(detail::protect(rb_str_new, s.data(), (long)s.length()))
  {
  }

  inline String::String(Identifier id) : Builtin_Object<T_STRING>(detail::protect(rb_str_new2, id.c_str()))
  {
  }

  template <typename... Arg_Ts>
  inline String String::format(char const* fmt, Arg_Ts&&...args)
  {
    size_t size = std::snprintf(nullptr, 0, fmt, std::forward<Arg_Ts>(args)...);
    std::string temp(size, '\0');

    // size+1 avoids trunctaing the string. Otherwise snprintf writes n - 1 characters
    // to allow space for null character but we don't need that since std::string
    // will add a null character internally at n + 1
    std::snprintf(&temp[0], size + 1, fmt, std::forward<Arg_Ts>(args)...);

    String s = String(temp.c_str());
    return s;
  }

  inline size_t String::length() const
  {
    return RSTRING_LEN(value());
  }

  inline char String::operator[](ptrdiff_t index) const
  {
    return RSTRING_PTR(value())[index];
  }

  inline char const* String::c_str() const
  {
    return RSTRING_PTR(value());
  }

  inline std::string String::str() const
  {
    return std::string(RSTRING_PTR(value()), length());
  }

  inline Identifier String::intern() const
  {
    return rb_intern(c_str());
  }
}

namespace Rice::detail
{
  template<>
  struct Type<String>
  {
    static bool verify()
    {
      return true;
    }
  };
  
  template<>
  class To_Ruby<String>
  {
  public:
    VALUE convert(String const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<String>
  {
  public:
    String convert(VALUE value)
    {
      return String(value);
    }
  };
}

// =========   Array.hpp   =========

#include <iterator>

namespace Rice
{
  //! A wrapper for the ruby Array class.
  /*! This class provides a C++-style interface to ruby's Array class and
   *  its associated rb_ary_* functions.
   *  Example:
   *  \code
   *    Array a;
   *    a.push(String("some string"));
   *    a.push(42);
   *  \endcode
   */
  class Array
    : public Builtin_Object<T_ARRAY>
  {
  public:
    //! Construct a new array
    Array();

    //! Wrap an existing array
    /*! \param v a ruby object, which must be of type T_ARRAY.
     */
    Array(Object v);

    //! Wrap an existing array
    /*! \param v a ruby object, which must be of type T_ARRAY.
     */
    Array(VALUE v);

    //! Construct an array from a sequence.
    /*! \param begin an iterator to the beginning of the sequence.
     *  \param end an iterator to the end of the sequence.
     */
    template<typename Iter_T>
    Array(Iter_T begin, Iter_T end);

    //! Construct an Array from a C array.
    /*! \param a a C array of type T and size n.
     */
    template<typename T, long n>
    Array(T const (&a)[n]);

  public:
    //! Return the size of the array.
    long size() const;

    //! Return the element at the given index.
    /*! \param index The index of the desired element.  The index may be
     *  negative, to indicate an offset from the end of the array.  If the
     *  index is out of bounds, this function has undefined behavior.
     *  \return the element at the given index.
     */
    Object operator[](long index) const;

  private:
    //! A helper class so array[index]=value can work.
    class Proxy;

  public:
    //! Return a reference to the element at the given index.
    /*! \param index The index of the desired element.  The index may be
     *  negative, to indicate an offset from the end of the array.  If the
     *  index is out of bounds, this function has undefined behavior.
     *  \return the element at the given index.
     */
    Proxy operator[](long index);

    //! Push an element onto the end of the array
    /*! \param v an object to push onto the array.
     *  \return the object which was pushed onto the array.
     */
    template<typename T>
    Object push(T const& obj);

    //! Pop an element from the end of the array
    /*! \return the object which was popped from the array, or Qnil if
     *  the array was empty.
     */
    Object pop();

    //! Unshift an element onto the beginning of the array
    /*! \param v an object to unshift onto the array.
     *  \return the object which was unshifted onto the array.
     */
    template<typename T>
    Object unshift(T const& obj);

    //! Shift an element from the beginning of the array
    /*! \return the object which was shifted from the array.
     */
    Object shift();

  private:
    template<typename Array_Ptr_T, typename Value_T>
    class Iterator;

    long position_of(long index) const;

  public:
    //! An iterator.
    typedef Iterator<Array*, Proxy> iterator;

    //! A const iterator.
    typedef Iterator<Array const*, Object> const_iterator;

    //! Return an iterator to the beginning of the array.
    iterator begin();

    //! Return a const iterator to the beginning of the array.
    const_iterator begin() const;

    //! Return an iterator to the end of the array.
    iterator end();

    //! Return a const iterator to the end of the array.
    const_iterator end() const;
  };

  //! A helper class so array[index]=value can work.
  class Array::Proxy
  {
  public:
    //! Construct a new Proxy
    Proxy(Array array, long index);

    //! Implicit conversion to Object.
    operator Object() const;

    //! Explicit conversion to VALUE.
    VALUE value() const;

    //! Assignment operator.
    template<typename T>
    Object operator=(T const& value);

  private:
    Array array_;
    long index_;
  };

  //! A helper class for implementing iterators for a Array.
  // TODO: This really should be a random-access iterator.
  template<typename Array_Ptr_T, typename Value_T>
  class Array::Iterator
  {
  public:
    using iterator_category = std::forward_iterator_tag;
    using value_type = Value_T;
    using difference_type = long;
    using pointer = Object*;
    using reference = Value_T&;

    Iterator(Array_Ptr_T array, long index);

    template<typename Array_Ptr_T_, typename Value_T_>
    Iterator(Iterator<Array_Ptr_T_, Value_T_> const& rhs);

    template<typename Array_Ptr_T_, typename Value_T_>
    Iterator& operator=(Iterator<Array_Ptr_T_, Value_T_> const& rhs);

    Iterator& operator++();
    Iterator operator++(int);
    Value_T operator*();
    Object* operator->();

    template<typename Array_Ptr_T_, typename Value_T_>
    bool operator==(Iterator<Array_Ptr_T_, Value_T_> const& rhs) const;

    template<typename Array_Ptr_T_, typename Value_T_>
    bool operator!=(Iterator<Array_Ptr_T_, Value_T_> const& rhs) const;

    Array_Ptr_T array() const;
    long index() const;

  private:
    Array_Ptr_T array_;
    long index_;

    Object tmp_;
  };
} // namespace Rice


// ---------   Array.ipp   ---------
#ifndef Rice__Array__ipp_
#define Rice__Array__ipp_

namespace Rice
{
  inline Array::Array() : Builtin_Object<T_ARRAY>(detail::protect(rb_ary_new))
  {
  }

  inline Array::Array(Object v) : Builtin_Object<T_ARRAY>(v)
  {
  }

  inline Array::Array(VALUE v) : Builtin_Object<T_ARRAY>(v)
  {
  }

  template<typename Iter_T>
  inline Array::Array(Iter_T it, Iter_T end) : Builtin_Object<T_ARRAY>(detail::protect(rb_ary_new))
  {
    for (; it != end; ++it)
    {
      push(*it);
    }
  }

  template<typename T, long n>
  inline Array::Array(T const (&a)[n]) : Builtin_Object<T_ARRAY>(detail::protect(rb_ary_new))
  {
    for (long j = 0; j < n; ++j)
    {
      push(a[j]);
    }
  }

  inline long Array::size() const
  {
    return RARRAY_LEN(this->value());
  }

  inline Object Array::operator[](long index) const
  {
    return detail::protect(rb_ary_entry, value(), position_of(index));
  }

  inline Array::Proxy Array::operator[](long index)
  {
    return Proxy(*this, position_of(index));
  }

  template<typename T>
  inline Object Array::push(T const& obj)
  {
    return detail::protect(rb_ary_push, value(), detail::To_Ruby<T>().convert(obj));
  }

  inline Object Array::pop()
  {
    return detail::protect(rb_ary_pop, value());
  }

  template<typename T>
  inline Object Array::unshift(T const& obj)
  {
    return detail::protect(rb_ary_unshift, value(), detail::To_Ruby<T>().convert(obj));
  }

  inline Object Array::shift()
  {
    return detail::protect(rb_ary_shift, value());
  }

  inline long Array::position_of(long index) const
  {
    if (index < 0)
    {
      return size() + index;
    }
    else
    {
      return static_cast<long>(index);
    }
  }

  inline Array::Proxy::Proxy(Array array, long index)
    : array_(array)
    , index_(index)
  {
  }

  inline Array::Proxy::operator Object() const
  {
    return detail::protect(rb_ary_entry, array_.value(), index_);
  }

  inline VALUE Array::Proxy::value() const
  {
    return detail::protect(rb_ary_entry, array_.value(), index_);
  }

  template<typename T>
  Object Array::Proxy::operator=(T const& value)
  {
    Object o = detail::To_Ruby<T>().convert(value);
    detail::protect(rb_ary_store, array_.value(), index_, o.value());
    return o;
  }

  template<typename Array_Ptr_T, typename Value_T>
  inline Array::Iterator<Array_Ptr_T, Value_T>::Iterator(Array_Ptr_T array, long index) :
    array_(array), index_(index)
  {
  }

  template<typename Array_Ptr_T, typename Value_T>
  template<typename Array_Ptr_T_, typename Value_T_>
  inline
    Array::Iterator<Array_Ptr_T, Value_T>::Iterator(Iterator<Array_Ptr_T_, Value_T_> const& rhs) :
      array_(rhs.array()) , index_(rhs.index()), tmp_()
  {
  }

  template<typename Array_Ptr_T, typename Value_T>
  template<typename Array_Ptr_T_, typename Value_T_>
  inline Array::Iterator<Array_Ptr_T, Value_T>& Array::Iterator<Array_Ptr_T, Value_T>::operator=(Iterator<Array_Ptr_T_, Value_T_> const& rhs)
  {
    array_ = rhs.array_;
    index_ = rhs.index_;
    return *this;
  }

  template<typename Array_Ptr_T, typename Value_T>
  inline Array::Iterator<Array_Ptr_T, Value_T>& Array::Iterator<Array_Ptr_T, Value_T>::operator++()
  {
    ++index_;
    return *this;
  }

  template<typename Array_Ptr_T, typename Value_T>
  inline Array::Iterator<Array_Ptr_T, Value_T> Array::Iterator<Array_Ptr_T, Value_T>::operator++(int)
  {
    Array copy(*this);
    ++(*this);
    return *this;
  }

  template<typename Array_Ptr_T, typename Value_T>
  inline Value_T Array::Iterator<Array_Ptr_T, Value_T>::operator*()
  {
    return (*array_)[index_];
  }

  template<typename Array_Ptr_T, typename Value_T>
  inline Object* Array::Iterator<Array_Ptr_T, Value_T>::operator->()
  {
    tmp_ = (*array_)[index_];
    return &tmp_;
  }

  template<typename Array_Ptr_T, typename Value_T>
  template<typename Array_Ptr_T_, typename Value_T_>
  inline bool Array::Iterator<Array_Ptr_T, Value_T>::operator==(Iterator<Array_Ptr_T_, Value_T_> const& rhs) const
  {
    return array_->value() == rhs.array_->value() && index_ == rhs.index_;
  }

  template<typename Array_Ptr_T, typename Value_T>
  template<typename Array_Ptr_T_, typename Value_T_>
  inline bool Array::Iterator<Array_Ptr_T, Value_T>::operator!=(Iterator<Array_Ptr_T_, Value_T_> const& rhs) const
  {
    return !(*this == rhs);
  }

  template<typename Array_Ptr_T, typename Value_T>
  Array_Ptr_T Array::Iterator<Array_Ptr_T, Value_T>::array() const
  {
    return array_;
  }

  template<typename Array_Ptr_T, typename Value_T>
  long Array::Iterator<Array_Ptr_T, Value_T>::index() const
  {
    return index_;
  }

  inline Array::iterator Array::begin()
  {
    return iterator(this, 0);
  }

  inline Array::const_iterator Array::begin() const
  {
    return const_iterator(this, 0);
  }

  inline Array::iterator Array::end()
  {
    return iterator(this, size());
  }

  inline Array::const_iterator Array::end() const
  {
    return const_iterator(this, size());
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Array>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class To_Ruby<Array>
  {
  public:
    VALUE convert(Array const& x)
    {
      return x.value();
    }
  };

  template<>
  class To_Ruby<Array&>
  {
  public:
    VALUE convert(Array const& x)
    {
      return x.value();
    }
  };

  template<>
  class To_Ruby<Array*>
  {
  public:
    VALUE convert(Array const* x)
    {
      return x->value();
    }
  };

  template<>
  class From_Ruby<Array>
  {
  public:
    Array convert(VALUE value)
    {
      return Array(value);
    }
  };
}
#endif // Rice__Array__ipp_

// =========   Hash.hpp   =========

#include <iterator>
#include <type_traits>

namespace Rice
{
  //! A wrapper for the ruby Hash class.
  //! This class provides a C++-style interface to ruby's Hash class and
  //! its associated rb_hash_* functions.
  //! Example:
  //! \code
  //!   Hash h;
  //!   h[42] = String("foo");
  //!   h[10] = String("bar");
  //!   std::cout << String(h[42]) << std::endl;
  //! \endcode
  class Hash: public Builtin_Object<T_HASH>
  {
  public:
    //! Construct a new hash.
    Hash();

    //! Wrap an existing hash.
    /*! \param v the hash to wrap.
     */
    Hash(Object v);

    //! Return the number of elements in the hash.
    size_t size() const;

  private:
    //! A helper class so hash[key]=value can work.
    class Proxy;

  public:
    //! Get the value for the given key.
    /*! \param key the key whose value should be retrieved from the hash.
     *  \return the value associated with the given key.
     */
    template<typename Key_T>
    Proxy const operator[](Key_T const& key) const;

    //! Get the value for the given key.
    /*! \param key the key whose value should be retrieved from the hash.
     *  \return the value associated with the given key.
     */
    template<typename Key_T>
    Proxy operator[](Key_T const& key);

    //! Get the value for the given key
    /*! The returned value is converted to the type given by Value_T.
     *  \param key the key whose value should be retrieved from the hash.
     *  \return the value associated with the given key, converted to C++
     *  type Value_T.
     */
    template<typename Value_T, typename Key_T>
    Value_T get(Key_T const& key);

    //! A helper class for dereferencing iterators
    class Entry;

    //! A helper class for implementing iterators for a Hash.
    template<typename Hash_Ptr_T, typename Value_T>
    class Iterator;

  public:
    //! An iterator.
    typedef Iterator<Hash*, Entry> iterator;

    //! A const iterator.
    typedef Iterator<Hash const*, Entry const> const_iterator;

  public:
    //! Return an iterator to the beginning of the hash.
    iterator begin();

    //! Return a const iterator to the beginning of the hash.
    const_iterator begin() const;

    //! Return an iterator to the end of the hash.
    iterator end();

    //! Return a const to the end of the hash.
    const_iterator end() const;
  };

  //! A helper class so hash[key]=value can work.
  class Hash::Proxy
  {
  public:
    //! Construct a new Proxy.
    Proxy(Hash* hash, Object key);

    //! Implicit conversion to Object.
    operator Object() const;

    //! Explicit conversion to VALUE.
    VALUE value() const;

    //! Assignment operator.
    template<typename T>
    Object operator=(T const& value);

  private:
    Hash* hash_;
    Object key_;
  };

  //! A helper class for dereferencing iterators
  /*! This class is intended to look similar to an std::pair.
   */
  class Hash::Entry
  {
  public:
    //! Construct a new Entry.
    Entry(Hash* hash, Object key);

    //! Copy constructor.
    Entry(Entry const& entry);

    Object const key;          //!< The key
    Object const& first;      //!< An alias for the key

    Proxy value;              //!< The value
    Proxy& second;           //!< An alias for the value

    Entry& operator=(Entry const& rhs);

    friend bool operator<(Entry const& lhs, Entry const& rhs);
  };

  bool operator<(Hash::Entry const& lhs, Hash::Entry const& rhs);

  //! A helper class for implementing iterators for a Hash.
  template<typename Hash_Ptr_T, typename Value_T>
  class Hash::Iterator
  {
  public:
    using iterator_category = std::input_iterator_tag;
    using value_type = Value_T;
    using difference_type = long;
    using pointer = Object*;
    using reference = Value_T&;

    //! Construct a new Iterator.
    Iterator(Hash_Ptr_T hash);

    //! Construct a new Iterator with a given start-at index point
    Iterator(Hash_Ptr_T hash, int start_at);

    //! Construct an Iterator from another Iterator of a different const
    //! qualification.
    template<typename Iterator_T>
    Iterator(Iterator_T const& iterator);

    //! Preincrement operator.
    Iterator& operator++();

    //! Postincrement operator.
    Iterator operator++(int);

    //! Dereference operator.
    Value_T operator*();

    //! Dereference operator.
    Value_T* operator->();

    //! Equality operator.
    bool operator==(Iterator const& rhs) const;

    //! Inequality operator.
    bool operator!=(Iterator const& rhs) const;

    template<typename Hash_Ptr_T_, typename Value_T_>
    friend class Hash::Iterator;

  protected:
    Object current_key();

    Array hash_keys();

  private:
    Hash_Ptr_T hash_;
    long current_index_;
    VALUE keys_;

    mutable typename std::remove_const<Value_T>::type tmp_;
  };
} // namespace Rice


// ---------   Hash.ipp   ---------
#ifndef Rice__Hash__ipp_
#define Rice__Hash__ipp_

#include <algorithm>

namespace Rice
{
  inline Hash::Hash() : Builtin_Object<T_HASH>(detail::protect(rb_hash_new))
  {
  }

  inline Hash::Hash(Object v) : Builtin_Object<T_HASH>(v)
  {
  }

  inline size_t Hash::size() const
  {
    return RHASH_SIZE(this->value());
  }

  inline Hash::Proxy::Proxy(Hash* hash, Object key) : hash_(hash), key_(key)
  {
  }

  inline Hash::Proxy::operator Object() const
  {
    return value();
  }

  inline VALUE Hash::Proxy::value() const
  {
    return detail::protect(rb_hash_aref, hash_->value(), key_.value());
  }

  template<typename T>
  inline Object Hash::Proxy::operator=(T const& value)
  {
    return detail::protect(rb_hash_aset, hash_->value(), key_.value(), detail::To_Ruby<T>().convert(value));
  }

  template<typename Key_T>
  inline Hash::Proxy const Hash::operator[](Key_T const& key) const
  {
    return Proxy(*this, detail::To_Ruby<Key_T>().convert(key));
  }

  template<typename Key_T>
  inline Hash::Proxy Hash::operator[](Key_T const& key)
  {
    return Proxy(this, detail::To_Ruby<Key_T>().convert(key));
  }

  template<typename Value_T, typename Key_T>
  inline Value_T Hash::get(Key_T const& key)
  {
    Object ruby_key(detail::To_Ruby<Key_T>().convert(key));
    Object value = operator[](ruby_key);
    try
    {
      return detail::From_Ruby<Value_T>().convert(value);
    }
    catch (Exception const& ex)
    {
      String s_key(ruby_key.to_s());
      throw Exception(
        ex,
        "%s while converting value for key %s",
        ex.what(),
        s_key.c_str());
    }
  }

  inline Hash::Entry::Entry(Hash* hash, Object key) :
    key(key), first(Hash::Entry::key), value(hash, key), second(Hash::Entry::value)
  {
  }

  inline Hash::Entry::Entry(Entry const& entry) :
    key(entry.key), first(Hash::Entry::key), value(entry.value), second(Hash::Entry::value)
  {
  }

  inline Hash::Entry& Hash::Entry::operator=(Hash::Entry const& other)
  {
    const_cast<Object&>(key) = const_cast<Object&>(other.key);

    this->value = other.value;
    this->second = this->value;

    return *this;
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Hash::Iterator<Hash_Ptr_T, Value_T>::Iterator(Hash_Ptr_T hash)
    : hash_(hash), current_index_(0), keys_(Qnil), tmp_(const_cast<Hash*>(hash), Qnil)
  {
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Hash::Iterator<Hash_Ptr_T, Value_T>::Iterator(Hash_Ptr_T hash, int start_at)
    : hash_(hash), current_index_(start_at), keys_(Qnil), tmp_(const_cast<Hash*>(hash), Qnil)
  {
  }

  template<typename Hash_Ptr_T, typename Value_T>
  template<typename Iterator_T>
  inline Hash::Iterator<Hash_Ptr_T, Value_T>::Iterator(Iterator_T const& iterator) :
    hash_(iterator.hash_), current_index_(iterator.current_index_), keys_(Qnil), tmp_(iterator.hash_, Qnil)
  {
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Hash::Iterator<Hash_Ptr_T, Value_T>& Hash::Iterator<Hash_Ptr_T, Value_T>::operator++()
  {
    // Ensure we're within the range
    if (current_index_ < hash_keys().size())
    {
      current_index_++;
    }

    return *this;
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Hash::Iterator<Hash_Ptr_T, Value_T> Hash::Iterator<Hash_Ptr_T, Value_T>::operator++(int)
  {
    Iterator copy(*this);
    ++(*this);
    return copy;
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Value_T Hash::Iterator<Hash_Ptr_T, Value_T>::operator*()
  {
    return Value_T(const_cast<Hash*>(hash_), current_key());
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Value_T* Hash::Iterator<Hash_Ptr_T, Value_T>::operator->()
  {
    this->tmp_ = Entry(const_cast<Hash*>(hash_), current_key());
    return &tmp_;
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline bool Hash::Iterator<Hash_Ptr_T, Value_T>::operator==(Iterator const& rhs) const
  {
    return hash_->value() == rhs.hash_->value()
      && current_index_ == rhs.current_index_;
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline bool Hash::Iterator<Hash_Ptr_T, Value_T>::operator!=(Iterator const& rhs) const
  {
    return !(*this == rhs);
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Object Hash::Iterator<Hash_Ptr_T, Value_T>::current_key()
  {
    return hash_keys()[current_index_];
  }

  template<typename Hash_Ptr_T, typename Value_T>
  inline Array Hash::Iterator<Hash_Ptr_T, Value_T>::hash_keys()
  {
    if (NIL_P(keys_))
    {
      keys_ = rb_funcall(hash_->value(), rb_intern("keys"), 0, 0);
    }

    return Array(keys_);
  }

  inline Hash::iterator Hash::begin()
  {
    return iterator(this);
  }

  inline Hash::const_iterator Hash::begin() const
  {
    return const_iterator(this);
  }

  inline Hash::iterator Hash::end()
  {
    return iterator(this, (int)size());
  }

  inline Hash::const_iterator Hash::end() const
  {
    return const_iterator(this, (int)size());
  }

  inline bool operator<(Rice::Hash::Entry const& lhs, Rice::Hash::Entry const& rhs)
  {
    Rice::Object lhs_key(lhs.key);
    Rice::Object rhs_key(rhs.key);
    if (lhs_key < rhs_key)
    {
      return true;
    }
    else if (lhs_key > rhs_key)
    {
      return false;
    }
    else if (Rice::Object(lhs.value.value()) < Rice::Object(rhs.value.value()))
    {
      return true;
    }
    else
    {
      return false;
    }
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Hash>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class To_Ruby<Hash>
  {
  public:
    VALUE convert(Hash const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<Hash>
  {
  public:
    Hash convert(VALUE value)
    {
      return Hash(value);
    }
  };
}

#endif // Rice__Hash__ipp_


// =========   Symbol.hpp   =========

#include <string>

namespace Rice
{
  //! A wrapper for ruby's Symbol class.
  /*! Symbols are internal identifiers in ruby.  They are singletons and
   *  can be thought of as frozen strings.  They differ from an Identifier
   *  in that they are in fact real Objects, but they can be converted
   *  back and forth between Identifier and Symbol.
   */
  class Symbol
    : public Object
  {
  public:
    //! Wrap an existing symbol.
    Symbol(VALUE v);

    //! Wrap an existing symbol.
    Symbol(Object v);

    //! Construct a Symbol from an Identifier.
    Symbol(Identifier id);

    //! Construct a Symbol from a null-terminated C string.
    Symbol(char const* s = "");

    //! Construct a Symbol from an std::string.
    Symbol(std::string const& s);

    //! Return a string representation of the Symbol.
    char const* c_str() const;

    //! Return a string representation of the Symbol.
    std::string str() const;

    //! Return the Symbol as an Identifier.
    Identifier to_id() const;
  };
} // namespace Rice


// ---------   Symbol.ipp   ---------
namespace Rice
{
  inline Symbol::Symbol(VALUE value) : Object(value)
  {
    detail::protect(rb_check_type, value, (int)T_SYMBOL);
  }

  inline Symbol::Symbol(Object value) : Object(value)
  {
    detail::protect(rb_check_type, value.value(), (int)T_SYMBOL);
  }

  inline Symbol::Symbol(char const* s)
    : Object(detail::protect(rb_id2sym, detail::protect(rb_intern, s)))
  {
  }

  inline Symbol::Symbol(std::string const& s)
    : Object(detail::protect(rb_id2sym, detail::protect(rb_intern, s.c_str())))
  {
  }

  inline Symbol::Symbol(Identifier id) : Object(detail::protect(rb_id2sym, id))
  {
  }

  inline char const* Symbol::c_str() const
  {
    return to_id().c_str();
  }

  inline std::string Symbol::str() const
  {
    return to_id().str();
  }

  inline Identifier Symbol::to_id() const
  {
    return rb_to_id(value());
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Symbol>
  {
    static bool verify()
    {
      return true;
    }
  };
  
  template<>
  class To_Ruby<Symbol>
  {
  public:
    VALUE convert(Symbol const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<Symbol>
  {
  public:
    Symbol convert(VALUE value)
    {
      return Symbol(value);
    }
  };
}



// =========   Module.hpp   =========


// ---------   Module_defn.hpp   ---------
#ifndef Rice__Module_defn__hpp_
#define Rice__Module_defn__hpp_


namespace Rice
{
  template <typename T>
  void validateType();

  //! A helper for defining a Module and its methods.
  /*! This class provides a C++-style interface to ruby's Module class and
   *  for defining methods on that module.
   *
   *  Many of the methods are defined in Module_impl.hpp so that they can
   *  return a reference to the most derived type.
   */
   // TODO: we can't inherit from Builtin_Object, because Class needs
   // type T_CLASS and Module needs type T_MODULE
  class Module : public Object
  {
  public:
    //! Default construct a Module and initialize it to rb_cObject.
    Module();

    //! Construct a Module from an existing Module object.
    Module(VALUE v);

    //! Construct a Module from an string that references a Module
    Module(std::string name, Object under = rb_cObject);

    //! Return the name of the module.
    String name() const;

    //! Return an array containing the Module's ancestors.
    /*! You will need to include Array.hpp to use this function.
     */
    Array ancestors() const;

    //! Return the module's singleton class.
    /*! You will need to include Class.hpp to use this function.
     */
    Class singleton_class() const;

    //! Evaluate the given string in the context of the module.
    /*! This is equivalant to calling obj.module_eval(s) from inside the
     *  interpreter.
     *  \return the result of the expression.
     */
    Object module_eval(String const& s);

    // Include these methods to call methods from Module but return
// an instance of the current classes. This is an alternative to
// using CRTP.


//! Include a module.
/*! \param inc the module to be included.
*  \return *this
*/
inline auto& include_module(Module const& inc)
{
  detail::protect(rb_include_module, this->value(), inc.value());
  return *this;
}

//! Define an instance method.
/*! The method's implementation can be a member function, plain function
 *  or lambda. The easiest case is a member function where the Ruby
 *  method maps one-to-one to the C++ method. In the case of a
 *  plain function or lambda, the first argument must be SELF - ie,
 *  the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters.
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define an instance function.
/*! The function implementation is a plain function or a static
 *  member function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_function(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function,
*   plain function or lambda. In all cases the first argument
*   must be SELF - ie, the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_singleton_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function, plain
 *  function or lambda.
 . A wrapper will be
 * generated which will convert the method
 *  from ruby types to C++ types before calling the function.  The return
 *  value will be converted back to ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a module function.
/*! A module function is a function that can be accessed either as a
 *  singleton method or as an instance method. It wrap a plain
 *  function, static member function or lambda.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_module_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  if (this->rb_type() != T_MODULE)
  {
    throw std::runtime_error("can only define module functions for modules");
  }

  define_function(name, std::forward<Function_T>(func), args...);
  define_singleton_function(name, std::forward<Function_T>(func), args...);
  return *this;
}

  protected:
    template<bool IsMethod, typename Function_T>
    void wrap_native_call(VALUE klass, std::string name, Function_T&& function, MethodInfo* methodInfo);
  };

  //! Define a new module in the namespace given by module.
  /*! \param module the module in which to define the new module.
   *  \param name the name of the new module.
   */
  Module define_module_under(Object module, char const * name);

  //! Define a new module in the default namespace.
  /*! \param name the name of the new module.
   */
  Module define_module(char const * name);

  //! Create a new anonymous module.
  /*! \return the new module.
   */
  Module anonymous_module();
}
#endif // Rice__Module_defn__hpp_
// ---------   Module.ipp   ---------
#ifndef Rice__Module__ipp_
#define Rice__Module__ipp_


namespace Rice
{
  inline Module::Module() : Object(rb_cObject)
  {
  }

  inline Module::Module(VALUE value) : Object(value)
  {
    if (::rb_type(value) != T_CLASS && ::rb_type(value) != T_MODULE)
    {
      throw Exception(
        rb_eTypeError,
        "Expected a Module but got a %s",
        detail::protect(rb_obj_classname, value)); // TODO: might raise an exception
    }
  }

  //! Construct a Module from an string that references a Module
  inline Module::Module(std::string name, Object under)
  {
    VALUE result = under.const_get(name);

    if (::rb_type(result) != T_MODULE)
    {
      throw Exception(
        rb_eTypeError,
        "Expected a Module but got a %s",
        detail::protect(rb_obj_classname, result)); // TODO: might raise an exception
    }

    this->set_value(result);
  }

  template<bool IsMethod, typename Function_T>
  inline void Module::wrap_native_call(VALUE klass, std::string name, Function_T&& function, MethodInfo* methodInfo)
  {
    // Make sure the return type and arguments have been previously seen by Rice
    using traits = detail::method_traits<Function_T, IsMethod>;
    detail::verifyType<typename traits::Return_T>();
    detail::verifyTypes<typename traits::Arg_Ts>();

    // Define a NativeFunction to bridge Ruby to C++
    detail::NativeFunction<VALUE, Function_T, IsMethod>::define(klass, name, std::forward<Function_T>(function), methodInfo);
  }

  inline Module define_module_under(Object module, char const* name)
  {
    return detail::protect(rb_define_module_under, module.value(), name);
  }

  inline Module define_module(char const* name)
  {
    return detail::protect(rb_define_module, name);
  }

  inline Module anonymous_module()
  {
    return detail::protect(rb_module_new);
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Module>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class To_Ruby<Module>
  {
  public:
    VALUE convert(Module const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<Module>
  {
  public:
    Module convert(VALUE value)
    {
      return Module(value);
    }
  };
}
#endif // Rice__Module__ipp_


// =========   Class.hpp   =========


// ---------   Class_defn.hpp   ---------
#ifndef Rice__Class_defn__hpp_
#define Rice__Class_defn__hpp_


/*!
 *  \example inheritance/animals.cpp
 *  \example callbacks/sample_callbacks.cpp
 */

namespace Rice
{
  //! A helper for defining a Class and its methods.
  /*! This class provides a C++-style interface to ruby's Class class and
   *  for defining methods on that class.
   */
  class Class: public Module
  {
  public:
    //! Default construct a new class wrapper and initialize it to
    //! rb_cObject.
    Class() = default;

    //! Construct a new class wrapper from a ruby object of type T_CLASS.
    Class(VALUE v);

    //! Disallow creation of an instance from Ruby code.
    /*! Undefines the singleton method allocate (or new, if using a
     *  version of ruby prior to 1.7) and the instance method initialize.
     */
    Class & undef_creation_funcs();

    // Include these methods to call methods from Module but return
// an instance of the current classes. This is an alternative to
// using CRTP.


//! Include a module.
/*! \param inc the module to be included.
*  \return *this
*/
inline auto& include_module(Module const& inc)
{
  detail::protect(rb_include_module, this->value(), inc.value());
  return *this;
}

//! Define an instance method.
/*! The method's implementation can be a member function, plain function
 *  or lambda. The easiest case is a member function where the Ruby
 *  method maps one-to-one to the C++ method. In the case of a
 *  plain function or lambda, the first argument must be SELF - ie,
 *  the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters.
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define an instance function.
/*! The function implementation is a plain function or a static
 *  member function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_function(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function,
*   plain function or lambda. In all cases the first argument
*   must be SELF - ie, the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_singleton_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function, plain
 *  function or lambda.
 . A wrapper will be
 * generated which will convert the method
 *  from ruby types to C++ types before calling the function.  The return
 *  value will be converted back to ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a module function.
/*! A module function is a function that can be accessed either as a
 *  singleton method or as an instance method. It wrap a plain
 *  function, static member function or lambda.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_module_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  if (this->rb_type() != T_MODULE)
  {
    throw std::runtime_error("can only define module functions for modules");
  }

  define_function(name, std::forward<Function_T>(func), args...);
  define_singleton_function(name, std::forward<Function_T>(func), args...);
  return *this;
}
  };

  //! Define a new class in the namespace given by module.
  /*! \param module the Module in which to define the class.
   *  \param name the name of the class.
   *  \param superclass the base class to use.
   *  \return the new class.
   */
  Class define_class_under(Object module, char const * name, const Class& superclass = rb_cObject);

  //! Define a new class in the default namespace.
  /*! \param name the name of the class.
   *  \param superclass the base class to use.
   *  \return the new class.
   */
  Class define_class(char const * name, const Class& superclass = rb_cObject);

  //! Create a new anonymous class.
  /*! \return the new class.
   */
  Class anonymous_class();
} // namespace Rice

#endif // Rice__Class_defn__hpp_
// ---------   Class.ipp   ---------
#ifndef Rice__Class__ipp_
#define Rice__Class__ipp_


namespace Rice
{
  inline Class::Class(VALUE value) : Module(value)
  {
    detail::protect(rb_check_type, value, (int)T_CLASS);
  }

  inline Class& Class::undef_creation_funcs()
  {
    detail::protect(rb_undef_alloc_func, value());
    detail::protect(rb_undef_method, value(), "initialize");
    return *this;
  }

  inline Class define_class_under(Object module, char const* name, const Class& superclass)
  {
    return detail::protect(rb_define_class_under, module.value(), name, superclass.value());
  }

  inline Class define_class(char const* name, const Class& superclass)
  {
    return detail::protect(rb_define_class, name, superclass.value());
  }

  inline Class anonymous_class()
  {
    return detail::protect(rb_class_new, rb_cObject);
  }
}

namespace Rice::detail
{
  template<>
  class To_Ruby<Class>
  {
  public:
    static VALUE convert(Class const& x)
    {
      return x.value();
    }
  };

  template<>
  class From_Ruby<Class>
  {
  public:
    Class convert(VALUE value)
    {
      return Class(value);
    }
  };
}
#endif // Rice__Class__ipp_

// =========   Struct.hpp   =========


namespace Rice
{
  //! A wrapper for creating Struct classes.
  /*! The Struct class is used for creating new Classes.  Note that the
   *  notation used here differs slightly from the notation inside the
   *  interpreter.
   *
   *  Inside the interpreter, calling Struct.new creates a new Class:
   *  \code
   *  irb(main):001:0> MyStruct = Struct.new(:a, :b, :c)
   *  => S
   *  irb(main):002:0> MyStruct.class
   *  => Class
   *  \endcode
   *
   *  Instantiating that Class creates an instance of that Class:
   *  \code
   *  irb(main):003:0> mystruct_instance = MyStruct.new
   *  => #<struct MyStruct a=nil, b=nil, c=nil>
   *  irb(main):004:0> mystruct_instance.class
   *  => MyStruct
   *  irb(main):005:0> mystruct_instance.class.ancestors
   *  => [MyStruct, Struct, Enumerable, Object, Kernel]
   *  \endcode
   *
   *  Thus, inside the interpreter, MyStruct is a Class which inherits
   *  from Struct, and mystruct_instance is an instance of MyStruct.
   *
   *  At the C++ level, we might do this instead:
   *  \code
   *  Struct rb_cMyStruct = define_struct()
   *    .define_member("a")
   *    .define_member("b")
   *    .define_member("c")
   *    .initialize("MyStruct");
   *  Struct::Instance mystruct_instance(rb_cMyStruct.new_instance());
   *  \endcode
   *
   * Here rb_cMyStruct is an instance of Struct and that mystruct_instance
   * is an instance of Struct::Instance.
   */
  class Struct : public Class
  {
  public:
    //! Define a new Struct member.
    /*! Defines a new member of the Struct.  Must be called before the
     *  Struct is initialized.
     *  \return *this
     */
    Struct& define_member(Identifier name);

    //! Initialize the Struct class.
    /*! Must be called after all Struct members have been defined.
     *  \param module the module under which to define the Struct.
     *  \param name the name of the Class at the ruby level.
     */
    Struct& initialize(Module module, Identifier name);

    //! Get the members in Struct.
    Array members() const;

    class Instance;
    friend class Instance;
    //friend Struct Rice::define_struct();

    //! Create a new instance of the Struct
    /*! \param args the arguments to the constructor.
     *  \return a new Struct::Instance
     */
    Instance new_instance(Array args = Array()) const;

  private:
    std::vector<Symbol> members_;
  };

  //! An instance of a Struct
  //! \sa Struct
  class Struct::Instance : public Builtin_Object<T_STRUCT>
  {
  public:
    //! Create a new Instance of a Struct.
    /*! \param type the Struct type to create.
     *  \param args the initial values for the objects of the instance.
     */
    Instance(Struct const& type,Array args = Array());

    //! Encapsulate an existing Struct instance.
    /*! \param type the Struct type to encapsulate.
     *  \param s the instance to encapsulate.
     */
    Instance(Struct const& type, Object s);

    //! Get a member, given its offset.
    /*! \param index the (integral) index into the Struct's internal
     *  array or its name (an Identifier or char const *)
     *  \return the member.
     */
    template<typename T>
    Object operator[](T index);

  private:
    Struct type_;
  };

  //! Define a new Struct
  Struct define_struct();

} // namespace Rice


// ---------   Struct.ipp   ---------

namespace Rice
{
  inline Struct& Struct::initialize(Module module, Identifier name)
  {
    Class struct_class(rb_cStruct);

    Object type = struct_class.vcall("new", this->members());

    set_value(type);
    module.const_set(name, type);

    return *this;
  }

  inline Struct& Struct::define_member(Identifier name)
  {
    if (value() != rb_cObject)
    {
      throw std::runtime_error("struct is already initialized");
    }

    members_.push_back(name.to_sym());

    return *this;
  }

  inline Array Struct::members() const
  {
    if (value() == rb_cObject)
    {
      // Struct is not yet defined
      return Array(members_.begin(), members_.end());
    }
    else
    {
      // Struct is defined, call Ruby API
      return rb_struct_s_members(this->value());
    }
  }

  inline Struct::Instance Struct::new_instance(Array args) const
  {
    Object instance = const_cast<Struct*>(this)->vcall("new", args);
    return Instance(*this, instance);
  }

  inline Struct::Instance::Instance(Struct const& type, Array args) :
    Builtin_Object<T_STRUCT>(type.new_instance(args)), type_(type)
  {
  }

  inline Struct::Instance::Instance(Struct const& type, Object s) :
    Builtin_Object<T_STRUCT>(s), type_(type)
  {
  }

  inline Struct define_struct()
  {
    return Struct();
  }

  template<typename T>
  inline Object Struct::Instance::operator[](T index)
  {
    return rb_struct_aref(value(), ULONG2NUM(index));
  }

  template<>
  inline Object Struct::Instance::operator[]<Identifier>(Identifier member)
  {
    return rb_struct_aref(value(), Symbol(member));
  }

  template<>
  inline Object Struct::Instance::operator[]<char const*>(char const* name)
  {
    return (*this)[Identifier(name)];
  }
}

namespace Rice::detail
{
  template<>
  struct Type<Struct>
  {
    static bool verify()
    {
      return true;
    }
  };
}

// =========   Address_Registration_Guard.hpp   =========


// ---------   Address_Registration_Guard_defn.hpp   ---------
#ifndef Rice__Address_Registration_Guard_defn__hpp_
#define Rice__Address_Registration_Guard_defn__hpp_


namespace Rice
{
  //! A guard to register a given address with the GC.
  /*! Calls rb_gc_register_address upon construction and
   *  rb_gc_unregister_address upon destruction.
   *  For example:
   *  \code
   *    Class Foo
   *    {
   *    public:
   *      Foo()
   *        : string_(rb_str_new2())
   *        , guard_(&string_);
   *
   *    private:
   *      VALUE string_;
   *      Address_Registration_Guard guard_;
   *    };
   *  \endcode
   */
  class Address_Registration_Guard
  {
  public:
    //! Register an address with the GC.
    /*  \param address The address to register with the GC.  The address
     *  must point to a valid ruby object (RObject).
     */
    Address_Registration_Guard(VALUE* address);

    //! Register an Object with the GC.
    /*! \param object The Object to register with the GC.  The object must
     *  not be destroyed before the Address_Registration_Guard is
     *  destroyed.
     */
    Address_Registration_Guard(Object* object);

    //! Unregister an address/Object with the GC.
    /*! Destruct an Address_Registration_Guard.  The address registered
     *  with the Address_Registration_Guard when it was constructed will
     *  be unregistered from the GC.
     */
    ~Address_Registration_Guard();

    // Disable copying
    Address_Registration_Guard(Address_Registration_Guard const& other) = delete;
    Address_Registration_Guard& operator=(Address_Registration_Guard const& other) = delete;

    // Enable moving
    Address_Registration_Guard(Address_Registration_Guard&& other);
    Address_Registration_Guard& operator=(Address_Registration_Guard&& other);

    //! Get the address that is registered with the GC.
    VALUE* address() const;

    /** Called during Ruby's exit process since we should not call
     * rb_gc unregister_address there
     */
    static void disable();

  private:
    inline static bool enabled = true;
    inline static bool exit_handler_registered = false;
    static void registerExitHandler();

  private:
    void registerAddress() const;
    void unregisterAddress();

    VALUE* address_ = nullptr;
  };
} // namespace Rice

#endif // Rice__Address_Registration_Guard_defn__hpp_
// ---------   Address_Registration_Guard.ipp   ---------
namespace Rice
{
  inline Address_Registration_Guard::Address_Registration_Guard(VALUE* address) : address_(address)
  {
    registerExitHandler();
    registerAddress();
  }

  inline Address_Registration_Guard::Address_Registration_Guard(Object* object)
    : address_(const_cast<VALUE*>(&object->value()))
  {
    registerExitHandler();
    registerAddress();
  }

  inline Address_Registration_Guard::~Address_Registration_Guard()
  {
    unregisterAddress();
  }

  inline Address_Registration_Guard::Address_Registration_Guard(Address_Registration_Guard&& other)
  {
    // We don't use the constructor because we don't want to double register this address
    address_ = other.address_;
    other.address_ = nullptr;
  }

  inline Address_Registration_Guard& Address_Registration_Guard::operator=(Address_Registration_Guard&& other)
  {
    this->unregisterAddress();

    this->address_ = other.address_;
    other.address_ = nullptr;
    return *this;
  }

  inline void Address_Registration_Guard::registerAddress() const
  {
    if (enabled)
    {
      detail::protect(rb_gc_register_address, address_);
    }
  }

  inline void Address_Registration_Guard::unregisterAddress()
  {
    if (enabled && address_)
    {
      detail::protect(rb_gc_unregister_address, address_);
    }

    address_ = nullptr;
  }

  inline VALUE* Address_Registration_Guard::address() const
  {
    return address_;
  }

  static void disable_all_guards(VALUE)
  {
    Address_Registration_Guard::disable();
  }

  inline void Address_Registration_Guard::registerExitHandler()
  {
    if (exit_handler_registered)
    {
      return;
    }

    detail::protect(rb_set_end_proc, &disable_all_guards, Qnil);
    exit_handler_registered = true;
  }

  inline void Address_Registration_Guard::disable()
  {
    enabled = false;
  }
} // Rice

// =========   global_function.hpp   =========


namespace Rice
{
   //! Define an global function
   /*! The method's implementation can be any function or static member
    *  function.  A wrapper will be generated which will convert the arguments
    *  from ruby types to C++ types before calling the function.  The return
    *  value will be converted back to ruby.
    *  \param name the name of the method
    *  \param func the implementation of the function, either a function
    *  pointer or a member function pointer.
    *  \param args a list of Arg instance used to define default parameters (optional)
    *  \return *this
    */
  template<typename Function_T, typename...Arg_Ts>
  void define_global_function(char const * name, Function_T&& func, Arg_Ts const& ...args);
} // Rice


// ---------   global_function.ipp   ---------

template<typename Function_T, typename...Arg_Ts>
void Rice::define_global_function(char const * name, Function_T&& func, Arg_Ts const& ...args)
{
  Module(rb_mKernel).define_module_function(name, std::forward<Function_T>(func), args...);
}

// Code involed in creating custom DataTypes (ie, Ruby classes that wrap C++ classes)

// =========   ruby_mark.hpp   =========
#ifndef ruby_mark__hpp
#define ruby_mark__hpp

//! Default function to call to mark a data object.
/*! This function can be specialized for a particular type to override
 *  the default behavior (which is to not mark any additional objects).
 */
namespace Rice
{
  template<typename T>
  void ruby_mark(T* data)
  {
  }
}
#endif // ruby_mark__hpp

// =========   default_allocation_func.hpp   =========

namespace Rice::detail
{
  //! A default implementation of an allocate_func.  This function does no
  //! actual allocation; the initialize_func can later do the real
  //! allocation with: DATA_PTR(self) = new Type(arg1, arg2, ...)
  template<typename T>
  VALUE default_allocation_func(VALUE klass);
}

// =========   Director.hpp   =========


namespace Rice
{
  /**
   * A Director works exactly as a SWIG %director works (thus the name).
   * You use this class to help build proxy classes so that polymorphism
   * works from C++ into Ruby. See the main README for how this class works.
   */
  class Director
  {
    public:
      //! Construct new Director. Needs the Ruby object so that the
      //  proxy class can call methods on that object.
      Director(Object self) : self_(self)
      {
      }

      virtual ~Director() = default;

      //! Raise a ruby exception when a call comes through for a pure virtual method
      /*! If a Ruby script calls 'super' on a method that's otherwise a pure virtual
       *  method, use this method to throw an exception in this case.
       */
      void raisePureVirtual() const
      {
        rb_raise(rb_eNotImpError, "Cannot call super() into a pure-virtual C++ method");
      }

      //! Get the Ruby object linked to this C++ instance
      Object getSelf() const { return self_; }

    private:

      // Save the Ruby object related to the instance of this class
      Object self_;

  };
}

// =========   Data_Type.hpp   =========


// ---------   Data_Type_defn.hpp   ---------
#ifndef Rice__Data_Type_defn__hpp_
#define Rice__Data_Type_defn__hpp_

#include <set>

namespace Rice
{
  //! A mechanism for binding ruby types to C++ types.
  /*! This class binds run-time types (Ruby VALUEs) to compile-time types
   *  (C++ types).  The binding can occur only once.
   */
  template<typename T>
  class Data_Type : public Class
  {
    static_assert(std::is_same_v<detail::intrinsic_type<T>, T>);

  public:
    //! Default constructor which does not bind.
    /*! No member functions must be called on this Data_Type except bind,
     *  until the type is bound.
     */
    Data_Type();

    //! Constructor which takes a Module.
    /*! Binds the type to the given VALUE according to the rules given
     *  above.
     *  \param klass the module to which to bind.
     */
    Data_Type(Module const & v);

    //! Destructor.
    virtual ~Data_Type();
 
    //! Return the Ruby class.
    /*! \return the ruby class to which the type is bound.
     */
    static Class klass();

    //! Return the Ruby data type.
    static rb_data_type_t* ruby_data_type();

    //! Assignment operator which takes a Module
    /*! \param klass must be the class to which this data type is already
     *  bound.
     *  \return *this
     */
    virtual Data_Type & operator=(Module const & klass);

    /*! Creates a singleton method allocate and an instance method called
     *  initialize which together create a new instance of the class.  The
     *  allocate method allocates memory for the object reference and the
     *  initialize method constructs the object.
     *  \param constructor an object that has a static member function
     *  construct() that constructs a new instance of T and sets the object's data
     *  member to point to the new instance.  A helper class Constructor
     *  is provided that does precisely this.
     *  \param args a list of Arg instance used to define default parameters (optional)
     *
     *  For example:
     *  \code
     *    define_class<Foo>("Foo")
     *      .define_constructor(Constructor<Foo>());
     *  \endcode
     */
    template<typename Constructor_T, typename...Arg_Ts>
    Data_Type<T> & define_constructor(Constructor_T constructor, Arg_Ts const& ...args);

    //! Register a Director class for this class.
    /*! For any class that uses Rice::Director to enable polymorphism
     *  across the languages, you need to register that director proxy
     *  class with this method. Not doing so will cause the resulting 
     *  library to die at run time when it tries to convert the base
     *  type into the Director proxy type.
     *
     *  This method takes no methodInfo, just needs the type of the
     *  Director proxy class.
     *
     *  For example:
     *  \code
     *    class FooDirector : public Foo, public Rice::Director {
     *      ...
     *    };
     *
     *    define_class<Foo>("Foo")
     *      .define_director<FooDirector>()
     *      .define_constructor(Constructor<FooDirector, Rice::Object>());
     *  \endcode
     */
    template<typename Director_T>
    Data_Type<T>& define_director();

    //! Determine if the type is bound.
    /*! \return true if the object is bound, false otherwise.
     */
    static bool is_bound();
    static void check_is_bound();

    // This is only for testing - DO NOT USE!!!
    static void unbind();

    static bool is_descendant(VALUE value);
  
    //! Define an iterator.
    /*! Essentially this is a conversion from a C++-style begin/end
     *  iterator to a Ruby-style \#each iterator.
     *  \param begin a member function pointer to a function that returns
     *  an iterator to the beginning of the sequence.
     *  \param end a member function pointer to a function that returns an
     *  iterator to the end of the sequence.
     *  \param name the name of the iterator.
     *  \return *this
     */

    template<typename Iterator_Func_T>
    Data_Type<T>& define_iterator(Iterator_Func_T begin, Iterator_Func_T end, std::string name = "each");

    template <typename Attribute_T>
    Data_Type<T>& define_attr(std::string name, Attribute_T attribute, AttrAccess access = AttrAccess::ReadWrite);
  
    template <typename Attribute_T>
    Data_Type<T>& define_singleton_attr(std::string name, Attribute_T attribute, AttrAccess access = AttrAccess::ReadWrite);

  // Include these methods to call methods from Module but return
// an instance of the current classes. This is an alternative to
// using CRTP.


//! Include a module.
/*! \param inc the module to be included.
*  \return *this
*/
inline auto& include_module(Module const& inc)
{
  detail::protect(rb_include_module, this->value(), inc.value());
  return *this;
}

//! Define an instance method.
/*! The method's implementation can be a member function, plain function
 *  or lambda. The easiest case is a member function where the Ruby
 *  method maps one-to-one to the C++ method. In the case of a
 *  plain function or lambda, the first argument must be SELF - ie,
 *  the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters.
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define an instance function.
/*! The function implementation is a plain function or a static
 *  member function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_function(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(this->value(), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function,
*   plain function or lambda. In all cases the first argument
*   must be SELF - ie, the current object. If it is specified as a VALUE, then
 *  the current Ruby object is passed. If it is specified as a C++ class,
 *  then the C++ object is passed. If you don't want to include the
 *  SELF argument see define_singleton_function.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_method(std::string name, Function_T&& func, const Arg_Ts&...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, true>::arity, args...);
  this->wrap_native_call<true>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a singleton method.
/*! The method's implementation can be a static member function, plain
 *  function or lambda.
 . A wrapper will be
 * generated which will convert the method
 *  from ruby types to C++ types before calling the function.  The return
 *  value will be converted back to ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_singleton_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  MethodInfo* methodInfo = new MethodInfo(detail::method_traits<Function_T, false>::arity, args...);
  this->wrap_native_call<false>(rb_singleton_class(*this), name, std::forward<Function_T>(func), methodInfo);
  return *this;
}

//! Define a module function.
/*! A module function is a function that can be accessed either as a
 *  singleton method or as an instance method. It wrap a plain
 *  function, static member function or lambda.
 *  Rice will automatically convert method method from Ruby to C++ and
 *  then convert the return value from C++ to Ruby.
 *  \param name the name of the method
 *  \param func the implementation of the function, either a function
 *  pointer or a member function pointer.
 *  \param args a list of Arg instance used to define default parameters (optional)
 *  \return *this
 */
template<typename Function_T, typename...Arg_Ts>
inline auto& define_module_function(std::string name, Function_T&& func, const Arg_Ts& ...args)
{
  if (this->rb_type() != T_MODULE)
  {
    throw std::runtime_error("can only define module functions for modules");
  }

  define_function(name, std::forward<Function_T>(func), args...);
  define_singleton_function(name, std::forward<Function_T>(func), args...);
  return *this;
}

  protected:
    //! Bind a Data_Type to a VALUE.
    /*! Throws an exception if the Data_Type is already bound to a
     *  different class.  Any existing instances of the Data_Type will be
     *  bound after this function returns.
     *  \param klass the ruby type to which to bind.
     *  \return *this
     */
    template <typename Base_T = void>
    static Data_Type bind(const Module& klass);

    template<typename T_, typename Base_T_>
    friend Rice::Data_Type<T_> define_class_under(Object module, char const * name);

    template<typename T_, typename Base_T_>
    friend Rice::Data_Type<T_> define_class(char const * name);

    template<bool IsMethod, typename Function_T>
    void wrap_native_call(VALUE klass, std::string name, Function_T&& function, MethodInfo* methodInfo);

  private:
    template<typename T_>
    friend class Data_Type;

    static inline VALUE klass_ = Qnil;

    // Typed Data support
    static inline rb_data_type_t* rb_data_type_ = nullptr;

    typedef std::set<Data_Type<T> *> Instances;

    static Instances & unbound_instances()
    {
      static Instances unbound_instances;
      return unbound_instances;
    }
  };

  //! Define a new data class in the namespace given by module.
  /*! By default the class will inherit from Ruby's rb_cObject. This
   *  can be overriden via the Base_T template parameter. Note that
   *  Base_T must already have been registered.
   *  \param T the C++ type of the wrapped class.
   *  \param module the the Module in which to define the class.
   *  \return the new class.
   */
  template<typename T, typename Base_T = void>
  Data_Type<T> define_class_under(Object module, char const* name);

  //! Define a new data class in the default namespace.
  /*! By default the class will inherit from Ruby's rb_cObject. This
   *  can be overriden via the Base_T template parameter. Note that
   *  Base_T must already have been registered.
   *  \param T the C++ type of the wrapped class.
   *  \param module the the Module in which to define the class.
   *  \return the new class.
   */
  template<typename T, typename Base_T = void>
  Data_Type<T> define_class(char const* name);
} // namespace Rice


#endif // Rice__Data_Type_defn__hpp_
// ---------   Data_Type.ipp   ---------
#ifndef Rice__Data_Type__ipp_
#define Rice__Data_Type__ipp_


#include <stdexcept>

namespace Rice
{
  template<typename T>
  void ruby_mark_internal(detail::Wrapper* wrapper)
  {
    // Tell the wrapper to mark the objects its keeping alive
    wrapper->ruby_mark();

    // Get the underlying data and call custom mark function (if any)
    T* data = static_cast<T*>(wrapper->get());
    ruby_mark<T>(data);
  }

  template<typename T>
  void ruby_free_internal(detail::Wrapper* wrapper)
  {
    delete wrapper;
  }

  template<typename T>
  size_t ruby_size_internal(const T* data)
  {
    return sizeof(T);
  }

  template<typename T>
  template <typename Base_T>
  inline Data_Type<T> Data_Type<T>::bind(const Module& klass)
  {
    if (is_bound())
    {
      std::string message = "Type " + detail::typeName(typeid(T)) + " is already bound to a different type";
      throw std::runtime_error(message.c_str());
    }

    klass_ = klass;

    rb_data_type_ = new rb_data_type_t();
    rb_data_type_->wrap_struct_name = strdup(Rice::detail::protect(rb_class2name, klass_));
    rb_data_type_->function.dmark = reinterpret_cast<void(*)(void*)>(&Rice::ruby_mark_internal<T>);
    rb_data_type_->function.dfree = reinterpret_cast<void(*)(void*)>(&Rice::ruby_free_internal<T>);
    rb_data_type_->function.dsize = reinterpret_cast<size_t(*)(const void*)>(&Rice::ruby_size_internal<T>);
    rb_data_type_->data = nullptr;
    rb_data_type_->flags = RUBY_TYPED_FREE_IMMEDIATELY;

    if constexpr (!std::is_void_v<Base_T>)
    {
      rb_data_type_->parent = Data_Type<Base_T>::ruby_data_type();
    }

    // Now register with the type registry
    detail::Registries::instance.types.add<T>(klass_, rb_data_type_);

    for (typename Instances::iterator it = unbound_instances().begin(),
      end = unbound_instances().end();
      it != end;
      unbound_instances().erase(it++))
    {
      (*it)->set_value(klass);
    }

    return Data_Type<T>();
  }

  template<typename T>
  inline void Data_Type<T>::unbind()
  {
    detail::Registries::instance.types.remove<T>();

    if (klass_ != Qnil)
    {
      klass_ = Qnil;
    }

    // There could be objects floating around using the existing rb_type so 
    // do not delete it. This is of course a memory leak.
    rb_data_type_ = nullptr;
  }

  template<typename T>
  inline Data_Type<T>::Data_Type() : Class(klass_ == Qnil ? rb_cObject : klass_)
  {
    if (!is_bound())
    {
      unbound_instances().insert(this);
    }
  }

  template<typename T>
  inline Data_Type<T>::Data_Type(Module const& klass) : Class(klass)
  {
    this->bind(klass);
  }

  template<typename T>
  inline Data_Type<T>::~Data_Type()
  {
    unbound_instances().erase(this);
  }

  template<typename T>
  inline rb_data_type_t* Data_Type<T>::ruby_data_type()
  {
    check_is_bound();
    return rb_data_type_;
  }

  template<typename T>
  inline Class Data_Type<T>::klass()
  {
    check_is_bound();
    return klass_;
  }

  template<typename T>
  inline Data_Type<T>& Data_Type<T>::operator=(Module const& klass)
  {
    this->bind(klass);
    return *this;
  }

  template<typename T>
  template<typename Constructor_T, typename...Arg_Ts>
  inline Data_Type<T>& Data_Type<T>::define_constructor(Constructor_T constructor, Arg_Ts const& ...args)
  {
    check_is_bound();

    // Define a Ruby allocator which creates the Ruby object
    detail::protect(rb_define_alloc_func, static_cast<VALUE>(*this), detail::default_allocation_func<T>);

    // Define an initialize function that will create the C++ object
    this->define_method("initialize", &Constructor_T::construct, args...);

    return *this;
  }

  template<typename T>
  template<typename Director_T>
  inline Data_Type<T>& Data_Type<T>::define_director()
  {
    if (!detail::Registries::instance.types.isDefined<Director_T>())
    {
      Data_Type<Director_T>::bind(*this);
    }

    // TODO - hack to fake Ruby into thinking that a Director is
    // the same as the base data type
    Data_Type<Director_T>::rb_data_type_ = Data_Type<T>::rb_data_type_;
    return *this;
  }

  template<typename T>
  inline bool Data_Type<T>::is_bound()
  {
    return klass_ != Qnil;
  }

  template<typename T>
  inline bool Data_Type<T>::is_descendant(VALUE value)
  {
    check_is_bound();
    return detail::protect(rb_obj_is_kind_of, value, klass_) == Qtrue;
  }

  template<typename T>
  inline void Data_Type<T>::check_is_bound()
  {
    if (!is_bound())
    {
      std::string message = "Type " + detail::typeName(typeid(T)) + " is not bound";
      throw std::runtime_error(message.c_str());
    }
  }

  template<typename T, typename Base_T>
  inline Data_Type<T> define_class_under(Object module, char const* name)
  {
    if (detail::Registries::instance.types.isDefined<T>())
    {
      return Data_Type<T>();
    }
    
    Class superKlass;

    if constexpr (std::is_void_v<Base_T>)
    {
      superKlass = rb_cObject;
    }
    else
    {
      superKlass = Data_Type<Base_T>::klass();
    }
    
    Class c = define_class_under(module, name, superKlass);
    c.undef_creation_funcs();
    return Data_Type<T>::template bind<Base_T>(c);
  }

  template<typename T, typename Base_T>
  inline Data_Type<T> define_class(char const* name)
  {
    if (detail::Registries::instance.types.isDefined<T>())
    {
      return Data_Type<T>();
    }

    Class superKlass;
    if constexpr (std::is_void_v<Base_T>)
    {
      superKlass = rb_cObject;
    }
    else
    {
      superKlass = Data_Type<Base_T>::klass();
    }

    Class c = define_class(name, superKlass);
    c.undef_creation_funcs();
    return Data_Type<T>::template bind<Base_T>(c);
  }

  template<typename T>
  template<typename Iterator_Func_T>
  inline Data_Type<T>& Data_Type<T>::define_iterator(Iterator_Func_T begin, Iterator_Func_T end, std::string name)
  {
    // Define a NativeIterator to bridge Ruby to C++
    detail::NativeIterator<T, Iterator_Func_T>::define(Data_Type<T>::klass(), name, begin, end);

    // Include enumerable support
    this->klass().include_module(rb_mEnumerable);

    return *this;
  }

  template <typename T>
  template <typename Attribute_T>
  inline Data_Type<T>& Data_Type<T>::define_attr(std::string name, Attribute_T attribute, AttrAccess access)
  {
    // Make sure the Attribute type has been previously seen by Rice
    detail::verifyType<typename detail::attribute_traits<Attribute_T>::attr_type>();

    // Define native attribute
    detail::NativeAttribute<Attribute_T>::define(klass_, name, std::forward<Attribute_T>(attribute), access);

    return *this;
  }

  template <typename T>
  template <typename Attribute_T>
  inline Data_Type<T>& Data_Type<T>::define_singleton_attr(std::string name, Attribute_T attribute, AttrAccess access)
  {
    // Make sure the Attribute type has been previously seen by Rice
    detail::verifyType<typename detail::attribute_traits<Attribute_T>::attr_type>();

    // Define native attribute
    VALUE singleton = detail::protect(rb_singleton_class, this->value());
    detail::NativeAttribute<Attribute_T>::define(singleton, name, std::forward<Attribute_T>(attribute), access);

    return *this;
  }

  template <typename T>
  template<bool IsMethod, typename Function_T>
  inline void Data_Type<T>::wrap_native_call(VALUE klass, std::string name, Function_T&& function, MethodInfo* methodInfo)
  {
    // Make sure the return type and arguments have been previously seen by Rice
    using traits = detail::method_traits<Function_T, IsMethod>;
    detail::verifyType<typename traits::Return_T>();
    detail::verifyTypes<typename traits::Arg_Ts>();

    // Define a NativeFunction to bridge Ruby to C++
    detail::NativeFunction<T, Function_T, IsMethod>::define(klass, name, std::forward<Function_T>(function), methodInfo);
  }
}
#endif

// =========   default_allocation_func.ipp   =========

namespace Rice::detail
{
  template<typename T>
  VALUE default_allocation_func(VALUE klass)
  {
    // Create a new Ruby object but since we do not yet have a C++ object
    // just pass a nullptr. It will be set via the Constructor call
    return TypedData_Wrap_Struct(klass, Data_Type<T>::ruby_data_type(), nullptr);
  }
}
// =========   Constructor.hpp   =========


namespace Rice
{
  //! Define a Type's Constructor and it's arguments.
  /*! E.g. for the default constructor on a Type:
      \code
        define_class<Test>()
          .define_constructor(Constructor<Test>());
      \endcode
  *
  *  The first template type must be the type being wrapped.
  *  Afterwards any extra types must match the appropriate constructor
  *  to be used in C++ when constructing the object.
  *
  *  For more information, see Rice::Data_Type::define_constructor.
  */
  template<typename T, typename...Arg_Ts>
  class Constructor
  {
  public:
    static void construct(VALUE self, Arg_Ts...args)
    {
      T* data = new T(args...);
      detail::replace<T>(self, Data_Type<T>::ruby_data_type(), data, true);
    }
  };

  //! Special-case Constructor used when defining Directors.
  template<typename T, typename...Arg_Ts>
  class Constructor<T, Object, Arg_Ts...>
  {
    public:
      static void construct(Object self, Arg_Ts...args)
      {
        T* data = new T(self, args...);
        detail::replace<T>(self.value(), Data_Type<T>::ruby_data_type(), data, true);
      }
  };
}

// =========   Data_Object.hpp   =========


// ---------   Data_Object_defn.hpp   ---------
#ifndef Rice__Data_Object_defn__hpp_
#define Rice__Data_Object_defn__hpp_

#include <optional>


/*! \file
 *  \brief Provides a helper class for wrapping and unwrapping C++
 *  objects as Ruby objects.
 */

namespace Rice
{
  //! A smartpointer-like wrapper for Ruby data objects.
  /*! A data object is a ruby object of type T_DATA, which is usually
   *  created by using the Data_Wrap_Struct or Data_Make_Struct macro.
   *  This class wraps creation of the data structure, providing a
   *  type-safe object-oriented interface to the underlying C interface.
   *  This class works in conjunction with the Data_Type class to ensure
   *  type safety.
   *
   *  Example:
   *  \code
   *    class Foo { };
   *    ...
   *    Data_Type<Foo> rb_cFoo = define_class("Foo");
   *    ...
   *    // Wrap:
   *    Data_Object<Foo> foo1(new Foo);
   *
   *    // Get value to return:
   *    VALUE v = foo1.value()
   *
   *    // Unwrap:
   *    Data_Object<Foo> foo2(v, rb_cFoo);
   *  \endcode
   */
  template<typename T>
  class Data_Object : public Object
  {
    static_assert(!std::is_pointer_v<T>);
    static_assert(!std::is_reference_v<T>);
    static_assert(!std::is_const_v<T>);
    static_assert(!std::is_volatile_v<T>);

  public:
    static T* from_ruby(VALUE value);

  public:
    //! Wrap a C++ object.
    /*! This constructor is analogous to calling Data_Wrap_Struct.  Be
     *  careful not to call this function more than once for the same
     *  pointer (in general, it should only be called for newly
     *  constructed objects that need to be managed by Ruby's garbage
     *  collector).
     *  \param obj the object to wrap.
     *  \param isOwner Should the Data_Object take ownership of the object?
     *  \param klass the Ruby class to use for the newly created Ruby
     *  object.
     */
    Data_Object(T* obj, bool isOwner = false, Class klass = Data_Type<T>::klass());
    Data_Object(T& obj, bool isOwner = false, Class klass = Data_Type<T>::klass());

    //! Unwrap a Ruby object.
    /*! This constructor is analogous to calling Data_Get_Struct.  Uses
     *  Data_Type<T>::klass as the class of the object.
     *  \param value the Ruby object to unwrap.
     */
    Data_Object(Object value);

    T& operator*() const; //!< Return a reference to obj_
    T* operator->() const; //!< Return a pointer to obj_
    T* get() const;        //!< Return a pointer to obj_

  private:
    static void check_ruby_type(VALUE value);
  };
} // namespace Rice

#endif // Rice__Data_Object_defn__hpp_


// ---------   Data_Object.ipp   ---------
#ifndef Rice__Data_Object__ipp_
#define Rice__Data_Object__ipp_


#include <algorithm>

namespace Rice
{
  template <typename T>
  Exception create_type_exception(VALUE value)
  {
    return Exception(rb_eTypeError, "Wrong argument type. Expected: %s. Received: %s.",
      detail::protect(rb_class2name, Data_Type<T>::klass().value()),
      detail::protect(rb_obj_classname, value));
  }

  template<typename T>
  inline Data_Object<T>::Data_Object(T& data, bool isOwner, Class klass)
  {
    VALUE value = detail::wrap(klass, Data_Type<T>::ruby_data_type(), data, isOwner);
    this->set_value(value);
  }

  template<typename T>
  inline Data_Object<T>::Data_Object(T* data, bool isOwner, Class klass)
  {
    VALUE value = detail::wrap(klass, Data_Type<T>::ruby_data_type(), data, isOwner);
    this->set_value(value);
  }

  template<typename T>
  inline Data_Object<T>::Data_Object(Object value) : Object(value)
  {
    check_ruby_type(value);
  }

  template<typename T>
  inline void Data_Object<T>::check_ruby_type(VALUE value)
  {
    if (rb_obj_is_kind_of(value, Data_Type<T>::klass()) == Qfalse)
    {
      throw create_type_exception<T>(value);
    }
  }

  template<typename T>
  inline T& Data_Object<T>::operator*() const
  {
    return *this->get();
  }

  template<typename T>
  inline T* Data_Object<T>::operator->() const
  {
    return this->get();
  }

  template<typename T>
  inline T* Data_Object<T>::get() const
  {
    if (this->value() == Qnil)
    {
      return nullptr;
    }
    else
    {
      return detail::unwrap<T>(this->value(), Data_Type<T>::ruby_data_type());
    }
  }

  template<typename T>
  inline T* Data_Object<T>::from_ruby(VALUE value)
  {
    if (Data_Type<T>::is_descendant(value))
    {
      return detail::unwrap<T>(value, Data_Type<T>::ruby_data_type());
    }
    else
    {
      throw create_type_exception<T>(value);
    }
  }
}

namespace Rice::detail
{
  template<typename T>
  class To_Ruby
  {
  public:
    VALUE convert(T& data)
    {
      // Get the ruby typeinfo
      std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType<T>(data);

      // We always take ownership of data passed by value (yes the parameter is T& but the template
      // matched <typename T> thus we have to tell wrap to copy the reference we are sending to it
      return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, true);
    }

    VALUE convert(const T& data)
    {
      // Get the ruby typeinfo
        std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType<T>(data);

      // We always take ownership of data passed by value (yes the parameter is T& but the template
      // matched <typename T> thus we have to tell wrap to copy the reference we are sending to it
      return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, true);
    }
  };

  template <typename T>
  class To_Ruby<T&>
  {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Return * returnInfo) : returnInfo_(returnInfo)
    {
    }

    VALUE convert(T& data)
    {
      // Note that T could be a pointer or reference to a base class while data is in fact a
      // child class. Lookup the correct type so we return an instance of the correct Ruby class
      std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType<T>(data);

      bool isOwner = this->returnInfo_ && this->returnInfo_->isOwner();
      return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, isOwner);
    }

    VALUE convert(const T& data)
    {
      // Note that T could be a pointer or reference to a base class while data is in fact a
      // child class. Lookup the correct type so we return an instance of the correct Ruby class
      std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType<T>(data);

      bool isOwner = this->returnInfo_ && this->returnInfo_->isOwner();
      return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, isOwner);
    }

  private:
    Return* returnInfo_ = nullptr;
  };

  template <typename T>
  class To_Ruby<T*>
  {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
    {
    }

    VALUE convert(T* data)
    {
      if (data)
      {
        // Note that T could be a pointer or reference to a base class while data is in fact a
        // child class. Lookup the correct type so we return an instance of the correct Ruby class
        std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType(*data);
        bool isOwner = this->returnInfo_ && this->returnInfo_->isOwner();
        return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, isOwner);
      }
      else
      {
        return Qnil;
      }
    }

    VALUE convert(const T* data)
    {
      if (data)
      {
        // Note that T could be a pointer or reference to a base class while data is in fact a
        // child class. Lookup the correct type so we return an instance of the correct Ruby class
        std::pair<VALUE, rb_data_type_t*> rubyTypeInfo = detail::Registries::instance.types.figureType(*data);
        bool isOwner = this->returnInfo_ && this->returnInfo_->isOwner();
        return detail::wrap(rubyTypeInfo.first, rubyTypeInfo.second, data, isOwner);
      }
      else
      {
        return Qnil;
      }
    }

  private:
    Return* returnInfo_ = nullptr;
  };

  template<typename T>
  class To_Ruby<Data_Object<T>>
  {
  public:
    VALUE convert(const Object& x)
    {
      return x.value();
    }
  };

  template <typename T>
  class From_Ruby
  {
    static_assert(!std::is_fundamental_v<intrinsic_type<T>>,
                  "Data_Object cannot be used with fundamental types");
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg * arg) : arg_(arg)
    {
    }
    
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_DATA &&
        Data_Type<T>::is_descendant(value);
    }

    T convert(VALUE value)
    {
      using Intrinsic_T = intrinsic_type<T>;

      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->template defaultValue<Intrinsic_T>();
      }
      else
      {
        return *Data_Object<Intrinsic_T>::from_ruby(value);
      }
    }

  private:
    Arg* arg_ = nullptr;
  };

  template<typename T>
  class From_Ruby<T&>
  {
    static_assert(!std::is_fundamental_v<intrinsic_type<T>>,
                  "Data_Object cannot be used with fundamental types");
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg * arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_DATA &&
        Data_Type<T>::is_descendant(value);
    }

    T& convert(VALUE value)
    {
      using Intrinsic_T = intrinsic_type<T>;

      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->template defaultValue<Intrinsic_T>();
      }
      else
      {
        return *Data_Object<Intrinsic_T>::from_ruby(value);
      }
    }

  private:
    Arg* arg_ = nullptr;
  };

  template<typename T>
  class From_Ruby<T*>
  {
    static_assert(!std::is_fundamental_v<intrinsic_type<T>>,
                  "Data_Object cannot be used with fundamental types");
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_DATA &&
        Data_Type<T>::is_descendant(value);
    }

    T* convert(VALUE value)
    {
      using Intrinsic_T = intrinsic_type<T>;

      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        return Data_Object<Intrinsic_T>::from_ruby(value);
      }
    }
  };

  template<typename T>
  class From_Ruby<Data_Object<T>>
  {
    static_assert(!std::is_fundamental_v<intrinsic_type<T>>,
                  "Data_Object cannot be used with fundamental types");
  public:
    static Data_Object<T> convert(VALUE value)
    {
      return Data_Object<T>(value);
    }
  };
}
#endif // Rice__Data_Object__ipp_


// =========   Enum.hpp   =========

#include <map>

namespace Rice
{
  /*!
   *  \example enum/sample_enum.cpp
   */

   //! A wrapper for enumerated types.
   /*! Provides a simple type-safe wrapper for enumerated types.  At the
    *  ruby level, the class will have convenience methods for iterating
    *  over all the defined enum values, converting the values to strings,
    *  and more.
    *
    *  \param Enum_T the enumerated type
    *
    *  Example:
    *  \code
    *    enum Color { Red, Green, Blue };
    *    Enum<Color> rb_cColor = define_enum<Color>("Color")
    *      .define_value("Red", Red)
    *      .define_value("Green", Green)
    *      .define_value("Blue", Blue);
    *  \endcode
    */
  template<typename Enum_T>
  class Enum : public Data_Type<Enum_T>
  {
    using Underlying_T = std::underlying_type_t<Enum_T>;

  public:

    Enum() = default;

    //! Construct and initialize.
    Enum(char const* name, Module module = rb_cObject);

    //! Define a new enum value.
    /*! \param name the name of the enum value.
     *  \param value the value to associate with name.
     *  \return *this
     */
    Enum<Enum_T>& define_value(std::string name, Enum_T value);

    //! Maps an enum value to the correct Ruby object
    /*! \param klass The bound Ruby class
     *  \param enumValue The enum value
     *  \return Object - The Ruby wrapper */
    static Object from_enum(Class klass, Enum_T enumValue);

  private:
    void define_methods(Data_Type<Enum_T> klass);

    static inline std::map<Enum_T, std::string> valuesToNames_;
  };

  template<typename T>
  Enum<T> define_enum(char const* name, Module module = rb_cObject);
} // namespace Rice


// ---------   Enum.ipp   ---------

#include <stdexcept>

namespace Rice
{
  template<typename Enum_T>
  Enum<Enum_T>::Enum(char const* name, Module module) : Data_Type<Enum_T>()
  {
    Data_Type<Enum_T> klass = define_class_under<Enum_T>(module, name);
    define_methods(klass);
  }

  template<typename Enum_T>
  inline Enum<Enum_T>& Enum<Enum_T>::define_value(std::string name, Enum_T value)
  {
    // Save mapping from value to name
    valuesToNames_[value] = name;

    // Store value as class constant available to Ruby
    Data_Object<Enum_T> object(value, true, Enum<Enum_T>::klass());
    this->const_set(name, object);

    return *this;
  }

  template<typename Enum_T>
  inline void Enum<Enum_T>::define_methods(Data_Type<Enum_T> klass)
  {
    // First we need a constructor
    klass.define_constructor(Constructor<Enum_T>());

    // Instance methods
    klass.define_method("to_s", [](Enum_T& self)
        {
          // We have to return string because we don't know if std::string support has
          // been included by the user
          return String(valuesToNames_[self]);
        })
      .define_method("to_i", [](Enum_T& self) ->  Underlying_T
        {
          return (Underlying_T)self;
        })
      .define_method("inspect", [](Enum_T& self)
        {
          std::stringstream result;
          VALUE rubyKlass = Enum<Enum_T>::klass().value();
          result << "#<" << detail::protect(rb_class2name, rubyKlass)
            << "::" << Enum<Enum_T>::valuesToNames_[self] << ">";

          // We have to return string because we don't know if std::string support has
          // been included by the user
          return String(result.str());
        })
      .define_method("hash", [](Enum_T& self) ->  Underlying_T
        {
          return (Underlying_T)self;
        })
      .define_method("eql?", [](Enum_T& self, Enum_T& other)
        {
          return self == other;
        });

    // Add aliases
    rb_define_alias(klass, "===", "eql?");

    // Add comparable support
    klass.include_module(rb_mComparable)
      .define_method("<=>", [](Enum_T& self, Enum_T& other)
    {
      if (self == other)
      {
        return 0;
      }
      else if (self < other)
      {
        return -1;
      }
      else
      {
        return 1;
      }
    });

    // Add enumerable support
    klass.include_module(rb_mEnumerable)
      .define_singleton_method("each", [](VALUE ruby_klass) -> VALUE
        {
          if (!rb_block_given_p())
          {
            return rb_enumeratorize_with_size(ruby_klass, Identifier("each").to_sym(),
                                      0, nullptr, 0);
          }

          for (auto& pair : valuesToNames_)
          {
            Enum_T enumValue = pair.first;
            VALUE value = detail::To_Ruby<Enum_T>().convert(enumValue);
            detail::protect(rb_yield, value);
          }

          return ruby_klass;
      }, Return().setValue())
      .define_singleton_method("from_int", [](VALUE ruby_klass, int32_t value) -> Object
      {
          auto iter = Enum<Enum_T>::valuesToNames_.find((Enum_T)value);
          if (iter == Enum<Enum_T>::valuesToNames_.end())
          {
            throw std::runtime_error("Unknown enum value: " + std::to_string(value));
          }

          std::string name = iter->second;
          return Object(ruby_klass).const_get(name);
      });
  }

  template<typename Enum_T>
  Enum<Enum_T> define_enum(char const* name, Module module)
  {
    if (detail::Registries::instance.types.isDefined<Enum_T>())
    {
      return Enum<Enum_T>();
    }

    return Enum<Enum_T>(name, module);
  }
}

// Dependent on Module, Class, Array and String

// =========   forward_declares.ipp   =========

namespace Rice
{
  // These methods cannot be defined where they are declared due to circular dependencies
  inline Class Object::class_of() const
  {
    return detail::protect(rb_class_of, value_);
  }

  inline String Object::to_s() const
  {
    return call("to_s");
  }

  inline String Object::class_name() const
  {
    return detail::protect(rb_obj_classname, this->value());
  }

  inline String Object::inspect() const
  {
    return call("inspect");
  }

  inline Object Object::instance_eval(String const& s)
  {
    const VALUE argv[] = { s.value() };
    return detail::protect(rb_obj_instance_eval, 1, &argv[0], this->value());
  }

  inline Object Object::vcall(Identifier id, Array args)
  {
    std::vector<VALUE> a(args.size());

    Array::const_iterator it = args.begin();
    Array::const_iterator end = args.end();

    for (int i = 0; it != end; i++, ++it)
    {
      a[i] = it->value();
    }

    return detail::protect(rb_funcall3, this->value(), id.id(), (int)args.size(), (const VALUE*)a.data());
  }

  inline std::ostream& operator<<(std::ostream& out, Object const& obj)
  {
    String s(obj.to_s());
    out << s.c_str();
    return out;
  }

  inline Identifier::Identifier(Symbol const& symbol) : id_(SYM2ID(symbol.value()))
  {
  }

  inline String Module::name() const
  {
    VALUE name = detail::protect(rb_mod_name, this->value());
    if (name == Qnil)
    {
      return String("");
    }
    else
    {
      return name;
    }
  }

  inline Array Module::ancestors() const
  {
    return detail::protect(rb_mod_ancestors, this->value());
  }

  inline Class Module::singleton_class() const
  {
    return CLASS_OF(value());
  }

  inline Object Module::module_eval(String const& s)
  {
    const VALUE argv[] = { s.value() };
    return detail::protect(rb_mod_module_eval, 1, &argv[0], this->value());
  }
}

#endif // Rice__hpp_
