# frozen_string_literal: true

require "mkmf"

# rubocop:disable Style/GlobalVars
$CXXFLAGS += " -std=c++11 "
$CXXFLAGS += " -g -O1 -ggdb "
$CFLAGS += " -g -O1 -ggdb "

if ENV["DEBUG"]
  $CXXFLAGS += "  -DDEBUG "
  $CFLAGS += "  -DDEBUG "
end
# rubocop:enable Style/GlobalVars

create_makefile("better_html_ext")
