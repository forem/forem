#include "../t1/Foo.hpp"
#include <rice/rice.hpp>

using namespace Rice;

extern "C"
void Init_t2()
{
  volatile Data_Type<Foo> foo;
}

