#include <rice/rice.hpp>

using namespace Rice;

namespace
{

enum Sample_Enum
{
  SE_FOO = 1,
  SE_BAR = 42,
  SE_BAZ = 100,
};

char const * description(Sample_Enum e)
{
  switch(e)
  {
    case SE_FOO: return "Fairly Ordinary Object";
    case SE_BAR: return "Beginner's All-purpose Ratchet";
    case SE_BAZ: return "Better than A Zebra";
  }
  return "???";
}

} // namespace

extern "C"
void Init_sample_enum()
{
    Rice::Enum<Sample_Enum> sample_enum_type =
      define_enum<Sample_Enum>("Sample_Enum")
      .define_value("FOO", SE_FOO)
      .define_value("BAR", SE_BAR)
      .define_value("BAZ", SE_BAZ);

    sample_enum_type
      .define_method("description", description);
}

