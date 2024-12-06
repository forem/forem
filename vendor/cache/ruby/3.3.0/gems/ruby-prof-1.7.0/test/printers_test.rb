#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'stringio'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrintersTest < TestCase
  def setup
    super
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    @result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      run_primes(1000, 5000)
    end
  end

  def test_printers
    output = ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1" ? STDOUT : StringIO.new('')

    printer = RubyProf::CallStackPrinter.new(@result)
    printer.print(output)

    printer = RubyProf::CallTreePrinter.new(@result)
    printer.print(:path => Dir.tmpdir)

    printer = RubyProf::FlatPrinter.new(@result)
    printer.print(output)

    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print(output)

    printer = RubyProf::GraphPrinter.new(@result)
    printer.print(output)
  end

  def test_print_to_files
    printer = RubyProf::DotPrinter.new(@result)
    File.open("#{Dir.tmpdir}/graph.dot", "w") {|f| printer.print(f)}

    printer = RubyProf::CallStackPrinter.new(@result)
    File.open("#{Dir.tmpdir}/stack.html", "w") {|f| printer.print(f, :application => "primes")}

    printer = RubyProf::MultiPrinter.new(@result)
    printer.print(:path => Dir.tmpdir, :profile => "multi", :application => "primes")

    ['graph.dot', 'multi.flat.txt', 'multi.graph.html', "multi.callgrind.out.#{$$}", 'multi.stack.html', 'stack.html'].each do |file_name|
      file_path = File.join(Dir.tmpdir, file_name)
      refute(File.empty?(file_path))
    end
  end

  def test_refuses_io_objects
    p = RubyProf::MultiPrinter.new(@result)
    begin
      p.print(STDOUT)
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/IO/, e.to_s)
    end
  end

  def test_refuses_non_hashes
    p = RubyProf::MultiPrinter.new (@result)
    begin
      p.print([])
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/hash/, e.to_s)
    end
  end

  def test_flat_string
    output = helper_test_flat_string(RubyProf::FlatPrinter)
    assert_match(/prime.rb/, output)
  end

  def helper_test_flat_string(klass)
    output = ''

    printer = klass.new(@result)
    printer.print(output)

    assert_match(/Thread ID: -?\d+/i, output)
    assert_match(/Fiber ID: -?\d+/i, output)
    assert_match(/Total: \d+\.\d+/i, output)
    assert_match(/Object#run_primes/i, output)
    output
  end

  def test_graph_html_string
    output = ''
    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print(output)

    assert_match(/<!DOCTYPE html>/i, output)
    assert_match( %r{<th>Total</th>}i, output)
    assert_match(/Object#run_primes/i, output)
  end

  def test_graph_string
    output = ''
    printer = RubyProf::GraphPrinter.new(@result)
    printer.print(output)

    assert_match(/Thread ID: -?\d+/i, output)
    assert_match(/Fiber ID: -?\d+/i, output)
    assert_match(/Total Time: \d+\.\d+/i, output)
    assert_match(/Object#run_primes/i, output)
  end

  def do_nothing
    start = Time.now
    while(Time.now == start)
    end
  end

  def test_all_with_small_percentiles
    result = RubyProf::Profile.profile do
      sleep 2
      do_nothing
    end

    # RubyProf::CallTreePrinter doesn't "do" a min_percent
    # RubyProf::FlatPrinter only outputs if self time > percent...
    for klass in [RubyProf::GraphPrinter, RubyProf::GraphHtmlPrinter]
      printer = klass.new(result)
      out = ''
      printer.print(out, :min_percent => 0.00000001)
      assert_match(/do_nothing/, out)
    end
  end
end
