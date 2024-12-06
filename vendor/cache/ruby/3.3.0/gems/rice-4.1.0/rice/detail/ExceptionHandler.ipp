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