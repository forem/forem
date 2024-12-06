#ifndef Rice__detail__default_allocation_func__hpp_
#define Rice__detail__default_allocation_func__hpp_

namespace Rice::detail
{
  //! A default implementation of an allocate_func.  This function does no
  //! actual allocation; the initialize_func can later do the real
  //! allocation with: DATA_PTR(self) = new Type(arg1, arg2, ...)
  template<typename T>
  VALUE default_allocation_func(VALUE klass);
}
#endif // Rice__detail__default_allocation_func__hpp_