#ifndef Rice__Return__hpp_
#define Rice__Return__hpp_

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

#include "Return.ipp"

#endif // Rice__Return__hpp_
