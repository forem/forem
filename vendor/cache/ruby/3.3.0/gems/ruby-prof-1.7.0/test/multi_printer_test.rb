#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class MSTPT
  def a
    100.times{b}
    300.times{c}
    c;c;c
  end

  def b
    sleep 0
  end

  def c
    5.times{b}
  end
end

class MultiPrinterTest < TestCase
  def test_refuses_io_objects
    # we don't need a real profile for this test
    p = RubyProf::MultiPrinter.new nil
    begin
      p.print(STDOUT)
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/IO/, e.to_s)
    end
  end

  def test_refuses_non_hashes
    # we don't need a real profile for this test
    p = RubyProf::MultiPrinter.new nil
    begin
      p.print([])
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/hash/, e.to_s)
    end
  end

  private

  def print(result)
    test = caller.first =~ /in `(.*)'/ ? $1 : "test"
    path = Dir.tmpdir
    profile = "ruby_prof_#{test}"
    printer = RubyProf::MultiPrinter.new(result)
    printer.print(:path => path, :profile => profile,
                  :threshold => 0, :min_percent => 0, :title => "ruby_prof #{test}")
    if RUBY_PLATFORM =~ /darwin/ && ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT']=="1"
      system("open '#{printer.stack_profile}'")
    end
    [File.read(printer.stack_profile), File.read(printer.graph_profile)]
  end
end
