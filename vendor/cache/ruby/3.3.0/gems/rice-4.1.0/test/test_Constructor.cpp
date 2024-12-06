#include "unittest.hpp"
#include "embed_ruby.hpp"

#include <rice/rice.hpp>

using namespace Rice;

TESTSUITE(Constructor);

namespace
{
  class Default_Constructible
  {
  public:
    Default_Constructible()
    {
    }
  };
}

SETUP(Array)
{
  embed_ruby();
}

TESTCASE(default_constructor)
{
  Data_Type<Default_Constructible> rb_cDefault_Constructible(anonymous_class());
  rb_cDefault_Constructible.define_constructor(Constructor<Default_Constructible>());
  Object o = rb_cDefault_Constructible.call("new");
  ASSERT_EQUAL(rb_cDefault_Constructible, o.class_of());
}


namespace
{
  class Non_Default_Constructible
  {
  public:
    Non_Default_Constructible(int i)
      : i_(i)
    {
    }

    int i() const
    {
      return i_;
    }

  private:
    int i_;
  };
}

TESTCASE(non_default_constructor)
{
  Data_Type<Non_Default_Constructible> rb_cNon_Default_Constructible(
      anonymous_class());
  rb_cNon_Default_Constructible
    .define_constructor(Constructor<Non_Default_Constructible, int>());
  Data_Object<Non_Default_Constructible> o =
    rb_cNon_Default_Constructible.call("new", 42);
  ASSERT_EQUAL(rb_cNon_Default_Constructible, o.class_of());
  ASSERT_EQUAL(42, o->i());
}

namespace
{
  int withArgsX;
  float withArgsY;
  bool withArgsYes;

  class WithDefaultArgs
  {
    public:
      WithDefaultArgs(int x, float y = 2.0, bool yes = false)
      {
        withArgsX = x;
        withArgsY = y;
        withArgsYes = yes;
      }
  };

  int withArgX;
  class WithOneArg
  {
    public:
      WithOneArg(int x = 14) {
        withArgX = x;
      }
  };
}

TESTCASE(constructor_supports_default_arguments)
{
  Class klass = define_class<WithDefaultArgs>("WithDefaultArgs").
    define_constructor(Constructor<WithDefaultArgs, int, float, bool>(),
           Arg("x"), Arg("y") = (float)2.0, Arg("yes") = (bool)false);

  klass.call("new", 4);
  ASSERT_EQUAL(4, withArgsX);
  ASSERT_EQUAL(2.0, withArgsY);
  ASSERT_EQUAL(false, withArgsYes);

  klass.call("new", 5, 3.0);
  ASSERT_EQUAL(5, withArgsX);
  ASSERT_EQUAL(3.0, withArgsY);
  ASSERT_EQUAL(false, withArgsYes);

  klass.call("new", 7, 12.0, true);
  ASSERT_EQUAL(7, withArgsX);
  ASSERT_EQUAL(12.0, withArgsY);
  ASSERT_EQUAL(true, withArgsYes);
}

TESTCASE(constructor_supports_single_default_argument)
{
  Class klass = define_class<WithOneArg>("WithOneArg").
    define_constructor(Constructor<WithOneArg, int>(),
          ( Arg("x") = 14 ));

  klass.call("new");
  ASSERT_EQUAL(14, withArgX);

  klass.call("new", 6);
  ASSERT_EQUAL(6, withArgX);
}
