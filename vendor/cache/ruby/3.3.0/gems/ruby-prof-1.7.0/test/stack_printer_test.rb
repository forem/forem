#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class STPT
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

class StackPrinterTest < TestCase
  def test_stack_can_be_printed
    start_time = Time.now
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      5.times{STPT.new.a}
    end

    end_time = Time.now
    expected_time = end_time - start_time

    file_contents = nil
    file_contents = print(result)
    re = /Thread: (\d+)(, Fiber: (\d+))? \([\.0-9]+.[\.0-9]+% ~ ([\.0-9]+)\)/
    assert_match(re, file_contents)
    file_contents =~ re
    actual_time = $4.to_f
    assert_in_delta(expected_time, actual_time, 0.1)
  end

  private

  def print(result)
    test = caller.first =~ /in `(.*)'/ ? $1 : "test"
    testfile_name = "#{Dir.tmpdir}/ruby_prof_#{test}.html"
    # puts "printing to #{testfile_name}"
    printer = RubyProf::CallStackPrinter.new(result)
    File.open(testfile_name, "w") {|f| printer.print(f, :threshold => 0, :min_percent => 0, :title => "ruby_prof #{test}")}
    system("open '#{testfile_name}'") if RUBY_PLATFORM =~ /darwin/ && ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT']=="1"
    assert File.exist?(testfile_name), "#{testfile_name} does not exist"
    assert File.readable?(testfile_name), "#{testfile_name} is no readable"
    File.read(testfile_name)
  end
end
