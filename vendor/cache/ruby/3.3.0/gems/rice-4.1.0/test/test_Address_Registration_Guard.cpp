#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Address_Registration_Guard);

SETUP(Address_Registration_Guard)
{
  embed_ruby();
}

TESTCASE(register_address)
{
  VALUE v = Qnil;
  Address_Registration_Guard g(&v);
}

TESTCASE(register_object)
{
  Object o;
  Address_Registration_Guard g(&o);
}

TESTCASE(get_address)
{
  VALUE v = Qnil;
  Address_Registration_Guard g(&v);
  ASSERT_EQUAL(&v, g.address());
}

TESTCASE(move_construct)
{
  VALUE value = detail::to_ruby("Value 1");
  
  Address_Registration_Guard guard1(&value);
  Address_Registration_Guard guard2(std::move(guard1));

  ASSERT((guard1.address() == nullptr));
  ASSERT_EQUAL(&value, guard2.address());
}

TESTCASE(move_assign)
{
  VALUE value1 = detail::to_ruby("Value 1");
  VALUE value2 = detail::to_ruby("Value 2");

  Address_Registration_Guard guard1(&value1);
  Address_Registration_Guard guard2(&value2);

  guard2 = std::move(guard1);

  ASSERT((guard1.address() == nullptr));
  ASSERT_EQUAL(&value1, guard2.address());
}

