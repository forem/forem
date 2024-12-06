#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Identifier);

SETUP(Identifier)
{
  embed_ruby();
}

TESTCASE(construct_from_id)
{
  ID id = rb_intern("foo");
  Identifier identifier(id);
  ASSERT_EQUAL(id, identifier.id());
}

TESTCASE(construct_from_symbol)
{
  Symbol symbol("FOO");
  Identifier identifier(symbol);
  ASSERT_EQUAL(rb_intern("FOO"), identifier.id());
}

TESTCASE(construct_from_c_string)
{
  Identifier identifier("Foo");
  ASSERT_EQUAL(rb_intern("Foo"), identifier.id());
}

TESTCASE(construct_from_string)
{
  Identifier identifier(std::string("Foo"));
  ASSERT_EQUAL(rb_intern("Foo"), identifier.id());
}

TESTCASE(copy_construct)
{
  Identifier identifier1("Foo");
  Identifier identifier2(identifier1);
  ASSERT_EQUAL(rb_intern("Foo"), identifier2.id());
}

TESTCASE(c_str)
{
  Identifier identifier("Foo");
  ASSERT_EQUAL("Foo", identifier.c_str());
}

TESTCASE(str)
{
  Identifier identifier("Foo");
  ASSERT_EQUAL(std::string("Foo"), identifier.str());
}

TESTCASE(implicit_conversion_to_id)
{
  Identifier identifier("Foo");
  ASSERT_EQUAL(rb_intern("Foo"), static_cast<ID>(identifier));
}

TESTCASE(to_sym)
{
  Identifier identifier("Foo");
  ASSERT_EQUAL(Symbol("Foo"), Symbol(identifier.to_sym()));
}

