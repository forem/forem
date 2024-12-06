#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'stringio'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrinterFlatTest < TestCase
  def run_profile
    RubyProf::Profile.profile(:measure_mode => RubyProf::WALL_TIME) do
      run_primes(1000, 5000)
    end
  end

  def flat_output_nth_column_values(output, n)
    only_method_calls = output.split("\n").select { |line| line =~ /^\s+\d+/ }
    only_method_calls.collect { |line| line.split(/\s+/)[n] }
  end

  def helper_test_flat_string(klass)
    output = StringIO.new

    printer = klass.new(self.run_profile)
    printer.print(output)

    assert_match(/Thread ID: -?\d+/i, output.string)
    assert_match(/Fiber ID: -?\d+/i, output.string)
    assert_match(/Total: \d+\.\d+/i, output.string)
    assert_match(/Object#run_primes/i, output.string)
    output.string
  end

  def assert_sorted(array)
    array = array.map(&:to_f) # allow for > 10s times to sort right, since lexographically 4.0 > 10.0
    assert_equal(array, array.sort.reverse)
  end

  def test_flat_string
    output = helper_test_flat_string(RubyProf::FlatPrinter)
    assert_match(/prime.rb/, output)
  end

  def test_flat_result_sorting_by_self_time_is_default
    printer = RubyProf::FlatPrinter.new(self.run_profile)

    output = StringIO.new
    printer.print(output)
    self_times = flat_output_nth_column_values(output.string, 3)

    assert_sorted self_times
  end

  def test_flat_result_sorting
    printer = RubyProf::FlatPrinter.new(self.run_profile)

    sort_method_with_column_number = {:total_time => 2, :self_time => 3, :wait_time => 4, :children_time => 5}

    sort_method_with_column_number.each_pair do |sort_method, n|
      output = StringIO.new
      printer.print(output, :sort_method => sort_method)

      times = flat_output_nth_column_values(output.string, n)
      assert_sorted(times)
    end
  end

  def test_flat_result_max_percent
    printer = RubyProf::FlatPrinter.new(self.run_profile)

    output = StringIO.new
    printer.print(output, max_percent: 1)
    self_percents = flat_output_nth_column_values(output.string, 1).map(&:to_f)

    assert self_percents.max < 1
  end

  def test_flat_result_filter_by_total_time
    printer = RubyProf::FlatPrinter.new(self.run_profile)

    output = StringIO.new
    printer.print(output, filter_by: :total_time, min_percent: 50)
    total_times = flat_output_nth_column_values(output.string, 2).map(&:to_f)

    assert (total_times.min / total_times.max) >= 0.5
  end

  def test_flat_result_filter_by_self_time
    printer = RubyProf::FlatPrinter.new(self.run_profile)

    output = StringIO.new
    printer.print(output, filter_by: :self_time, min_percent: 0.1)
    self_percents = flat_output_nth_column_values(output.string, 1).map(&:to_f)

    assert self_percents.min >= 0.1
  end
end
