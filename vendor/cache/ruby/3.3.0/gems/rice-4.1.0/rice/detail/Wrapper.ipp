#include <memory>
#include "InstanceRegistry.hpp"

namespace Rice::detail
{
  inline void Wrapper::ruby_mark()
  {
    for (VALUE value : this->keepAlive_)
    {
      rb_gc_mark(value);
    }
  }

  inline void Wrapper::addKeepAlive(VALUE value)
  {
    this->keepAlive_.push_back(value);
  }

  template <typename T>
  class WrapperValue : public Wrapper
  {
  public:
    WrapperValue(T& data): data_(std::move(data))
    {
    }

    ~WrapperValue()
    {
      Registries::instance.instances.remove(this->get());
    }

    void* get() override
    {
      return (void*)&this->data_;
    }

  private:
    T data_;
  };

  template <typename T>
  class WrapperReference : public Wrapper
  {
  public:
    WrapperReference(T& data): data_(data)
    {
    }

    ~WrapperReference()
    {
      Registries::instance.instances.remove(this->get());
    }

    void* get() override
    {
      return (void*)&this->data_;
    }

  private:
    T& data_;
  };

  template <typename T>
  class WrapperPointer : public Wrapper
  {
  public:
    WrapperPointer(T* data, bool isOwner) : data_(data), isOwner_(isOwner)
    {
    }

    ~WrapperPointer()
    {
      Registries::instance.instances.remove(this->get());

      if (this->isOwner_)
      {
        delete this->data_;
      }
    }

    void* get() override
    {
      return (void*)this->data_;
    }

  private:
    T* data_ = nullptr;
    bool isOwner_ = false;
  };

  // ---- Helper Functions -------
  template <typename T, typename Wrapper_T>
  inline VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T& data, bool isOwner)
  {
    VALUE result = Registries::instance.instances.lookup(&data);

    if (result != Qnil)
      return result;

    Wrapper* wrapper = nullptr;

    if constexpr (!std::is_void_v<Wrapper_T>)
    {
      wrapper = new Wrapper_T(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else if (isOwner)
    {
      wrapper = new WrapperValue<T>(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else
    {
      wrapper = new WrapperReference<T>(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }

    Registries::instance.instances.add(wrapper->get(), result);

    return result;
  };

  template <typename T, typename Wrapper_T>
  inline VALUE wrap(VALUE klass, rb_data_type_t* rb_type, T* data, bool isOwner)
  {
    VALUE result = Registries::instance.instances.lookup(data);

    if (result != Qnil)
      return result;

    Wrapper* wrapper = nullptr;

    if constexpr (!std::is_void_v<Wrapper_T>)
    {
      wrapper = new Wrapper_T(data);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }
    else
    {
      wrapper = new WrapperPointer<T>(data, isOwner);
      result = TypedData_Wrap_Struct(klass, rb_type, wrapper);
    }

    Registries::instance.instances.add(wrapper->get(), result);
    return result;
  };

  template <typename T>
  inline T* unwrap(VALUE value, rb_data_type_t* rb_type)
  {
    Wrapper* wrapper = getWrapper(value, rb_type);

    if (wrapper == nullptr)
    {
      std::string message = "Wrapped C++ object is nil. Did you override " + 
                            std::string(detail::protect(rb_obj_classname, value)) + 
                            "#initialize and forget to call super?";

      throw std::runtime_error(message);
    }

    return static_cast<T*>(wrapper->get());
  }
    
  inline Wrapper* getWrapper(VALUE value, rb_data_type_t* rb_type)
  {
    Wrapper* wrapper = nullptr;
    TypedData_Get_Struct(value, Wrapper, rb_type, wrapper);
    return wrapper;
  }

  template <typename T>
  inline void replace(VALUE value, rb_data_type_t* rb_type, T* data, bool isOwner)
  {
    WrapperPointer<T>* wrapper = nullptr;
    TypedData_Get_Struct(value, WrapperPointer<T>, rb_type, wrapper);
    if (wrapper)
    {
      Registries::instance.instances.remove(wrapper->get());
      delete wrapper;
    }

    wrapper = new WrapperPointer<T>(data, isOwner);
    RTYPEDDATA_DATA(value) = wrapper;

    Registries::instance.instances.add(data, value);
  }

  inline Wrapper* getWrapper(VALUE value)
  {
    // Turn off spurious warning on g++ 12
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#endif
    return static_cast<Wrapper*>(RTYPEDDATA_DATA(value));
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
  }
} // namespace
