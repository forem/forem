#ifndef Rice__detail__from_ruby__ipp_
#define Rice__detail__from_ruby__ipp_

#include <optional>
#include <stdexcept>
#include "../Exception_defn.hpp"
#include "../Arg.hpp"
#include "RubyFunction.hpp"

/* This file implements conversions from Ruby to native values fo fundamental types 
   such as bool, int, float, etc. It also includes conversions for chars and strings */
namespace Rice::detail
{
  // ===========  short  ============
  template<>
  class From_Ruby<short>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<short>();
      }
      else
      {
        return protect(rb_num2short_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<short&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<short>();
      }
      else
      {
        this->converted_ = protect(rb_num2short_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    short converted_ = 0;
  };

  template<>
  class From_Ruby<short*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    short* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2short_inline, value);
        return &this->converted_;
      }
    }

  private:
    short converted_ = 0;
  };

  // ===========  int  ============
  template<>
  class From_Ruby<int>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<int>();
      }
      else
      {
        return (int)protect(rb_num2long_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<int&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<int>();
      }
      else
      {
        this->converted_ = (int)protect(rb_num2long_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    int converted_ = 0;
  };

  template<>
  class From_Ruby<int*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    int* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (int)protect(rb_num2long_inline, value);
        return &this->converted_;
      }
    }

  private:
    int converted_;
  };

  // ===========  long  ============
  template<>
  class From_Ruby<long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long>();
      }
      else
      {
        return protect(rb_num2long_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long>();
      }
      else
      {
        this->converted_ = protect(rb_num2long_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    long converted_ = 0;
  };

  template<>
  class From_Ruby<long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2long_inline, value);
        return &this->converted_;
      }
    }

  private:
    long converted_ = 0;
  };

  // ===========  long long  ============
  template<>
  class From_Ruby<long long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long long>();
      }
      else
      {
        return protect(rb_num2ll_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<long long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<long long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ll_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    long long converted_ = 0;
  };

  template<>
  class From_Ruby<long long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    long long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ll_inline, value);
        return &this->converted_;
      }
    }

  private:
    long long converted_ = 0;
  };

  // ===========  unsigned short  ============
  template<>
  class From_Ruby<unsigned short>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned short>();
      }
      else
      {
        return protect(rb_num2ushort, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned short&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned short>();
      }
      else
      {
        this->converted_ = protect(rb_num2ushort, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned short converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned short*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned short* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ushort, value);
        return &this->converted_;
      }
    }

  private:
    unsigned short converted_ = 0;
  };

  // ===========  unsigned int  ============
  template<>
  class From_Ruby<unsigned int>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned int>();
      }
      else
      {
        return (unsigned int)protect(rb_num2ulong_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned int&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned int>();
      }
      else
      {
        this->converted_ = (unsigned int)protect(rb_num2ulong_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned int converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned int*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned int* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (unsigned int)protect(rb_num2ulong_inline, value);
        return &this->converted_;
      }
    }

  private:
    unsigned int converted_ = 0;
  };

  // ===========  unsigned long  ============
  template<>
  class From_Ruby<unsigned long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long convert(VALUE value)
    {
      if (this->arg_ && this->arg_->isValue())
      {
        return (unsigned long)value;
      }
      else if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long>();
      }
      else
      {
        return protect(rb_num2ulong_inline, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ulong_inline, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned long converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ulong_inline, value);
        return &this->converted_;
      }
    }

  private:
    unsigned long converted_ = 0;
  };

  // ===========  unsigned long long  ============
  template<>
  class From_Ruby<unsigned long long>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long convert(VALUE value)
    {
      if (this->arg_ && this->arg_->isValue())
      {
        return value;
      }
      else if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long long>();
      }
      else
      {
        return protect(rb_num2ull, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<unsigned long long&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned long long>();
      }
      else
      {
        this->converted_ = protect(rb_num2ull, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    unsigned long long converted_ = 0;
  };

  template<>
  class From_Ruby<unsigned long long*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FIXNUM;
    }

    unsigned long long* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2ull, value);
        return &this->converted_;
      }
    }

  private:
    unsigned long long converted_ = 0;
  };

  // ===========  bool  ============
  template<>
  class From_Ruby<bool>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
            ruby_type == RUBY_T_FALSE ||
            ruby_type == RUBY_T_NIL;
    }

    bool convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<bool>();
      }
      else
      {
        return RTEST(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<bool&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
             ruby_type == RUBY_T_FALSE ||
             ruby_type == RUBY_T_NIL;
    }

    bool& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<bool>();
      }
      else
      {
        this->converted_ = RTEST(value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    bool converted_ = false;
  };

  template<>
  class From_Ruby<bool*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      ruby_value_type ruby_type = (ruby_value_type)rb_type(value);
      return ruby_type == RUBY_T_TRUE ||
             ruby_type == RUBY_T_FALSE ||
             ruby_type == RUBY_T_NIL;
    }

    bool* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = RTEST(value);
        return &this->converted_;
      }
    }

  private:
    bool converted_ = false;
  };

  // ===========  char  ============
  template<typename T>
  inline T charFromRuby(VALUE value)
  {
    switch (rb_type(value))
    {
      case T_STRING:
      {
        if (RSTRING_LEN(value) == 1)
        {
          return RSTRING_PTR(value)[0];
        }
        else
        {
          throw std::invalid_argument("from_ruby<char>: string must have length 1");
        }
        break;
      }
      case T_FIXNUM:
      {
        return From_Ruby<long>().convert(value) & 0xff;
        break;
      }
      default:
      {
        throw Exception(rb_eTypeError, "wrong argument type %s (expected % s)",
          detail::protect(rb_obj_classname, value), "char type");
      }
    }
  }
  
  template<>
  class From_Ruby<char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<char>();
      }
      else
      {
        return charFromRuby<char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<char&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<char>();
      }
      else
      {
        this->converted_ = charFromRuby<char>(value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    char converted_ = 0;
  };

  template<>
  class From_Ruby<char*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        detail::protect(rb_check_type, value, (int)T_STRING);
        return RSTRING_PTR(value);
      }
    }
  };
  
  // This is mostly for testing. NativeFunction removes const before calling From_Ruby
  template<>
  class From_Ruby<char const*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    char const* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        detail::protect(rb_check_type, value, (int)T_STRING);
        return RSTRING_PTR(value);
      }
    }
  };

  // ===========  unsinged char  ============
  template<>
  class From_Ruby<unsigned char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    unsigned char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<unsigned char>();
      }
      else
      {
        return charFromRuby<unsigned char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  // ===========  signed char  ============
  template<>
  class From_Ruby<signed char>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_STRING;
    }

    signed char convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<signed char>();
      }
      else
      {
        return charFromRuby<signed char>(value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  // ===========  double  ============
  template<>
  class From_Ruby<double>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<double>();
      }
      else
      {
        return protect(rb_num2dbl, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<double&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<double>();
      }
      else
      {
        this->converted_ = protect(rb_num2dbl, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    double converted_;
  };

  template<>
  class From_Ruby<double*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    double* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = protect(rb_num2dbl, value);
        return &this->converted_;
      }
    }

  private:
    double converted_;
  };

  // ===========  float  ============
  template<>
  class From_Ruby<float>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<float>();
      }
      else
      {
        return (float)protect(rb_num2dbl, value);
      }
    }
  
  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class From_Ruby<float&>
  {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg)
    {
    }

    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float& convert(VALUE value)
    {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue())
      {
        return this->arg_->defaultValue<float>();
      }
      else
      {
        this->converted_ = (float)protect(rb_num2dbl, value);
        return this->converted_;
      }
    }

  private:
    Arg* arg_ = nullptr;
    float converted_;
  };

  template<>
  class From_Ruby<float*>
  {
  public:
    bool is_convertible(VALUE value)
    {
      return rb_type(value) == RUBY_T_FLOAT;
    }

    float* convert(VALUE value)
    {
      if (value == Qnil)
      {
        return nullptr;
      }
      else
      {
        this->converted_ = (float)protect(rb_num2dbl, value);
        return &this->converted_;
      }
    }

  private:
    float converted_;
  };
}
#endif // Rice__detail__from_ruby__ipp_
