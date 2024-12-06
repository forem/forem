#ifndef Rice__detail__ExceptionHandler_defn__hpp_
#define Rice__detail__ExceptionHandler_defn__hpp_

#include <memory>
#include "ruby.hpp"

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