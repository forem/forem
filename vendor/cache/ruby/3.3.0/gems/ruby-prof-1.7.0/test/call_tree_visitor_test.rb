#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class CallTreeVisitorTest < TestCase
  def test_visit
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C1.sleep_wait
    end

    visitor = RubyProf::CallTreeVisitor.new(result.threads.first.call_tree)

    method_names = Array.new

    visitor.visit do |call_tree, event|
      method_names << call_tree.target.full_name if event == :enter
    end

    assert_equal(3, method_names.length)
    assert_equal("CallTreeVisitorTest#test_visit", method_names[0])
    assert_equal("<Class::RubyProf::C1>#sleep_wait", method_names[1])
    assert_equal("Kernel#sleep", method_names[2])
  end
end

