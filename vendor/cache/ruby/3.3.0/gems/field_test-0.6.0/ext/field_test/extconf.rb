require "mkmf-rice"

$CXXFLAGS << " -std=c++17 $(optflags)"

create_makefile("field_test/ext")
