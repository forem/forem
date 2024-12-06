# encoding: utf-8

require "ruby-prof"

at_exit {
  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
}
RubyProf.start
