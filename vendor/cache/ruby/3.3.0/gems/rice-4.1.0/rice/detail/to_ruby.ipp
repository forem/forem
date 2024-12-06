#include "RubyFunction.hpp"
#include "../Return.hpp"

namespace Rice
{
  namespace detail
  {
    template<>
    class To_Ruby<void>
    {
    public:
      VALUE convert(void const*)
      {
        return Qnil;
      }
    };

    template<>
    class To_Ruby<std::nullptr_t>
    {
    public:
      VALUE convert(std::nullptr_t const)
      {
        return Qnil;
      }
    };

    template<>
    class To_Ruby<short>
    {
    public:
      VALUE convert(short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<short&>
    {
    public:
      VALUE convert(short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<int>
    {
    public:
      VALUE convert(int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<int&>
    {
    public:
      VALUE convert(int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_int2num_inline, (int)x);
#else
        return RB_INT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<long>
    {
    public:
      VALUE convert(long const& x)
      {
        return protect(rb_long2num_inline, x);
      }
    };

    template<>
    class To_Ruby<long&>
    {
    public:
      VALUE convert(long const& x)
      {
        return protect(rb_long2num_inline, x);
      }
    };

    template<>
    class To_Ruby<long long>
    {
    public:
      VALUE convert(long long const& x)
      {
        return protect(rb_ll2inum, x);
      }
    };

    template<>
    class To_Ruby<long long&>
    {
    public:
      VALUE convert(long long const& x)
      {
        return protect(rb_ll2inum, x);
      }
    };

    template<>
    class To_Ruby<unsigned short>
    {
    public:
      VALUE convert(unsigned short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned short&>
    {
    public:
      VALUE convert(unsigned short const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned int>
    {
    public:
      VALUE convert(unsigned int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned int&>
    {
    public:
      VALUE convert(unsigned int const& x)
      {
#ifdef rb_int2num_inline
        return protect(rb_uint2num_inline, (unsigned int)x);
#else
        return RB_UINT2NUM(x);
#endif
      }
    };

    template<>
    class To_Ruby<unsigned long>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ulong2num_inline, x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long&>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ulong2num_inline, x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long long>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ull2inum, (unsigned long long)x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<unsigned long long&>
    {
    public:
      To_Ruby() = default;

      explicit To_Ruby(Return* returnInfo) : returnInfo_(returnInfo)
      {
      }

      VALUE convert(unsigned long long const& x)
      {
        if (this->returnInfo_ && this->returnInfo_->isValue())
        {
          return x;
        }
        else
        {
          return protect(rb_ull2inum, (unsigned long long)x);
        }
      }

    private:
      Return* returnInfo_ = nullptr;
    };

    template<>
    class To_Ruby<float>
    {
    public:
      VALUE convert(float const& x)
      {
        return protect(rb_float_new, (double)x);
      }
    };

    template<>
    class To_Ruby<float&>
    {
    public:
      VALUE convert(float const& x)
      {
        return protect(rb_float_new, (double)x);
      }
    };

    template<>
    class To_Ruby<double>
    {
    public:
      VALUE convert(double const& x)
      {
        return protect(rb_float_new, x);
      }
    };

    template<>
    class To_Ruby<double&>
    {
    public:
      VALUE convert(double const& x)
      {
        return protect(rb_float_new, x);
      }
    };

    template<>
    class To_Ruby<bool>
    {
    public:
      VALUE convert(bool const& x)
      {
        return x ? Qtrue : Qfalse;
      }
    };

    template<>
    class To_Ruby<bool&>
    {
    public:
      VALUE convert(bool const& x)
      {
        return x ? Qtrue : Qfalse;
      }
    };

    template<>
    class To_Ruby<char>
    {
    public:
      VALUE convert(char const& x)
      {
        return To_Ruby<int>().convert(x);
      }
    };

    template<>
    class To_Ruby<char&>
    {
    public:
      VALUE convert(char const& x)
      {
        return To_Ruby<int>().convert(x);
      }
    };

    template<>
    class To_Ruby<unsigned char>
    {
    public:
      VALUE convert(unsigned char const& x)
      {
        return To_Ruby<unsigned int>().convert(x);
      }
    };

    template<>
    class To_Ruby<unsigned char&>
    {
    public:
      VALUE convert(unsigned char const& x)
      {
        return To_Ruby<unsigned int>().convert(x);
      }
    };

    template<>
    class To_Ruby<signed char>
    {
    public:
      VALUE convert(signed char const& x)
      {
        return To_Ruby<signed int>().convert(x);
      }
    };

    template<>
    class To_Ruby<signed char&>
    {
    public:
      VALUE convert(signed char const& x)
      {
        return To_Ruby<signed int>().convert(x);
      }
    };

    template<>
    class To_Ruby<char*>
    {
    public:
      VALUE convert(char const* x)
      {
        if (strlen(x) > 0 && x[0] == ':')
        {
          size_t symbolLength = strlen(x) - 1;
          char* symbol = new char[symbolLength];
          strncpy(symbol, x + 1, symbolLength);
          ID id = protect(rb_intern2, symbol, (long)symbolLength);
          delete[] symbol;
          return protect(rb_id2sym, id);
        }
        else
        {
          return protect(rb_str_new2, x);
        }
      }
    };

    template<int N>
    class To_Ruby<char[N]>
    {
    public:
      VALUE convert(char const x[])
      {
        if (N > 0 && x[0] == ':')
        {
          // N count includes a NULL character at the end of the string
          constexpr size_t symbolLength = N - 1;
          char symbol[symbolLength];
          strncpy(symbol, x + 1, symbolLength);
          ID id = protect(rb_intern, symbol);
          return protect(rb_id2sym, id);
        }
        else
        {
          return protect(rb_str_new2, x);
        }
      }
    };
  }
}