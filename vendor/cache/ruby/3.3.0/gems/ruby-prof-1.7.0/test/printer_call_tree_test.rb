#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrinterCallTreeTest < TestCase
  def setup
    super
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    @result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      run_primes(1000, 5000)
    end
  end

  def test_call_tree_string
    printer = RubyProf::CallTreePrinter.new(@result)

    printer.print(:path => Dir.tmpdir)
    main_output_file_name = File.join(Dir.tmpdir, "callgrind.out.#{$$}")
    assert(File.exist?(main_output_file_name))
    output = File.read(main_output_file_name)
    assert_match(/fn=Object::find_primes/i, output)
    assert_match(/events: wall_time/i, output)
    refute_match(/d\d\d\d\d\d/, output) # old bug looked [in error] like Object::run_primes(d5833116)
  end
end
