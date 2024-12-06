#include "../traits/rice_traits.hpp"

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
