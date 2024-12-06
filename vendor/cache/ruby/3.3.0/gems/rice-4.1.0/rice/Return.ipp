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
