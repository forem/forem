#include "unittest.hpp"
#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Jump_Tag);

SETUP(Jump_Tag)
{
}

TESTCASE(construct)
{
  Jump_Tag jump_tag(42);
  ASSERT_EQUAL(42, jump_tag.tag);
}

