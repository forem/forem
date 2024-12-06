#ifndef Rice__HandlerRegistration__hpp_
#define Rice__HandlerRegistration__hpp_

#include "detail/HandlerRegistry.hpp"

namespace Rice
{
  // Register exception handler
  template<typename Exception_T, typename Functor_T>
  detail::HandlerRegistry register_handler(Functor_T functor)
  {
    return detail::Registries::instance.handlers.add<Exception_T, Functor_T>(std::forward<Functor_T>(functor));
  }
}
#endif // Rice__HandlerRegistration__hpp_
