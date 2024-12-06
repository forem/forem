#include <rice/rice.hpp>

using namespace Rice;

namespace
{

  class CallbackHolder
  {
    public:

    void registerCallback(Rice::Object cb)
    {
      callback_ = cb;
    }

    Rice::Object fireCallback(Rice::String param)
    {
      return callback_.call("call", param);
    }

    Rice::Object callback_;
  };

} // namespace

extern "C"
void Init_sample_callbacks()
{
    define_class<CallbackHolder>("CallbackHolder")
      .define_constructor(Constructor<CallbackHolder>())
      .define_method("register_callback", &CallbackHolder::registerCallback)
      .define_method("fire_callback", &CallbackHolder::fireCallback);
}

