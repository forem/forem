#ifndef Rice__detail__HandlerRegistry__hpp_
#define Rice__detail__HandlerRegistry__hpp_

#include "ExceptionHandler.hpp"

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

#include "HandlerRegistry.ipp"

#endif // Rice__detail__HandlerRegistry__hpp_

