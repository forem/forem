#ifndef Rice__detail__NativeRegistry__hpp
#define Rice__detail__NativeRegistry__hpp

#include <unordered_map>
#include <any>

#include "ruby.hpp"

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
#include "NativeRegistry.ipp"

#endif // Rice__detail__NativeRegistry__hpp