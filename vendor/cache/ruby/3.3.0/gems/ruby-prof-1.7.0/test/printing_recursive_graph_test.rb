#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'stringio'

# --- code to be tested ---
module PRGT
  extend self

  def f(n)
    n.times { sleep 0.1 }
  end

  def g(n)
    n.times { sleep 0.2 }
  end

  def run
    2.times { f(2); g(4) }
  end
end

# --- expected test output ---
=begin
Measure Mode: wall_time
Thread ID: 1307675084040
Fiber ID: 1307708787440
Total Time: 2.0939999999973224
Sort by:

  %total   %self      total       self       wait      child            calls     name
--------------------------------------------------------------------------------
                      1.657      0.000      0.000      1.657              2/2     Integer#times
  79.13%   0.00%      1.657      0.000      0.000      1.657                2     PRGT#g
                      1.657      0.000      0.000      1.657              2/5     Integer#times
--------------------------------------------------------------------------------
                      2.094      2.094      0.000      0.000            12/12     Integer#times
 100.00% 100.00%      2.094      2.094      0.000      0.000               12     Kernel#sleep
--------------------------------------------------------------------------------
                      0.437      0.000      0.000      0.437              2/2     Integer#times
  20.87%   0.00%      0.437      0.000      0.000      0.437                2     PRGT#f
                      0.437      0.000      0.000      0.437              2/5     Integer#times
--------------------------------------------------------------------------------
                      0.437      0.000      0.000      0.437              2/5     PRGT#f
                      1.657      0.000      0.000      1.657              2/5     PRGT#g
                      2.094      0.000      0.000      2.094              1/5     PRGT#run
 100.00%   0.00%      2.094      0.000      0.000      2.094                5    *Integer#times
                      2.094      2.094      0.000      0.000            12/12     Kernel#sleep
                      1.657      0.000      0.000      1.657              2/2     PRGT#g
                      0.437      0.000      0.000      0.437              2/2     PRGT#f
--------------------------------------------------------------------------------
                      2.094      0.000      0.000      2.094              1/1     PrintingRecursiveGraphTest#setup
 100.00%   0.00%      2.094      0.000      0.000      2.094                1     PRGT#run
                      2.094      0.000      0.000      2.094              1/5     Integer#times
--------------------------------------------------------------------------------
 100.00%   0.00%      2.094      0.000      0.000      2.094                1     PrintingRecursiveGraphTest#setup
                      2.094      0.000      0.000      2.094              1/1     PRGT#run

* indicates recursively called methods
=end

class PrintingRecursiveGraphTest < TestCase
  def setup
    super
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    @result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      PRGT.run
    end
  end

  def test_printing_rescursive_graph
    printer = RubyProf::GraphPrinter.new(@result)
    buffer = ''
    printer.print(StringIO.new(buffer))
    puts buffer if ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1"

    refute_nil(buffer)
  end
end
