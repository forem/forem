#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrinterGraphHtmlTest < TestCase
  def setup
    super
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    @result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      run_primes(1000, 5000)
    end
  end

  def graph_html_output_nth_column_values(output, n)
    only_root_calls = output.split('<tr class="method">')
    only_root_calls.delete_at(0)
    only_root_calls.collect {|line| line.scan(/[\d\.]+/)[n - 1] }
  end

  def assert_sorted array
    array = array.map{|n| n.to_f} # allow for > 10s times to sort right, since lexographically 4.0 > 10.0
    assert_equal array, array.sort.reverse, "Array #{array.inspect} is not sorted"
  end

  def test_graph_html_string
    output = ''
    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print(output)

    assert_match(/<!DOCTYPE html>/i, output)
    assert_match( %r{<th>Total</th>}i, output)
    assert_match(/Object#run_primes/i, output)
  end

  def test_graph_html_result_sorting_by_total_time_is_default
    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print(output = '')
    total_times = graph_html_output_nth_column_values(output, 3)

    assert_sorted total_times
  end

  def test_graph_html_result_sorting
    printer = RubyProf::GraphHtmlPrinter.new(@result)

    sort_method_with_column_number = {:total_time => 3, :self_time => 4, :wait_time => 5, :children_time => 6}

    sort_method_with_column_number.each_pair do |sort_method, n|
      printer.print(output = '', :sort_method => sort_method)
      times = graph_html_output_nth_column_values(output, n)
      assert_sorted times
    end
  end
end
