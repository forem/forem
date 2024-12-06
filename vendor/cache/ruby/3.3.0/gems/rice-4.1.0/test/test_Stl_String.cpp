#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <ruby/encoding.h>
#include <rice/stl.hpp>

#include <optional>

using namespace Rice;

TESTSUITE(StlString);

SETUP(StlString)
{
  embed_ruby();
}

TESTCASE(std_string_to_ruby)
{
  ASSERT(rb_equal(String("").value(), detail::to_ruby(std::string(""))));
  ASSERT(rb_equal(String("foo").value(), detail::to_ruby(std::string("foo"))));
}

TESTCASE(std_string_to_ruby_encoding)
{
  VALUE value = detail::to_ruby(std::string("Some String"));
  Object object(value);
  Object encoding = object.call("encoding");
  Object encodingName = encoding.call("name");
  ASSERT_EQUAL("ASCII-8BIT", detail::From_Ruby<std::string>().convert(encodingName));
}

TESTCASE(std_string_to_ruby_encoding_utf8)
{
  rb_encoding* defaultEncoding = rb_default_external_encoding();
  
  VALUE utf8Encoding = rb_enc_from_encoding(rb_utf8_encoding());
  rb_enc_set_default_external(utf8Encoding);

  VALUE value = detail::to_ruby(std::string("Some String"));
  Object object(value);
  Object encoding = object.call("encoding");
  Object encodingName = encoding.call("name");
  ASSERT_EQUAL("UTF-8", detail::From_Ruby<std::string>().convert(encodingName));

  rb_enc_set_default_external(rb_enc_from_encoding(defaultEncoding));
}

TESTCASE(std_string_from_ruby)
{
  ASSERT_EQUAL(std::string(""), detail::From_Ruby<std::string>().convert(rb_str_new2("")));
  ASSERT_EQUAL(std::string("foo"), detail::From_Ruby<std::string>().convert(rb_str_new2("foo")));

  ASSERT_EXCEPTION_CHECK(
    Exception,
    detail::From_Ruby<std::string>().convert(rb_float_new(15.512)),
    ASSERT_EQUAL("wrong argument type Float (expected String)", ex.what())
  );
}

TESTCASE(std_string_to_ruby_with_binary)
{
  Rice::String got = detail::to_ruby(std::string("\000test", 5));

  ASSERT_EQUAL(String(std::string("\000test", 5)), got);
  ASSERT_EQUAL(5ul, got.length());
}

TESTCASE(std_string_from_ruby_with_binary)
{
  std::string got = detail::From_Ruby<std::string>().convert(rb_str_new("\000test", 5));
  ASSERT_EQUAL(5ul, got.length());
  ASSERT_EQUAL(std::string("\000test", 5), got);
}