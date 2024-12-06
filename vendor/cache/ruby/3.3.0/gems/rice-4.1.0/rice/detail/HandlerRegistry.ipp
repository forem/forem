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
