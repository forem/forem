#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class MeasureWallTimeTest < TestCase
  def setup
    # OSX on github actions are very slow so double the deltas to avoid test failures
    @delta_multiplier = self.osx? && ENV["GITHUB_ACTIONS"] ? 4 : 1
  end

  def test_class_methods
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C1.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.1, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('MeasureWallTimeTest#test_class_methods', methods[0].full_name)
    assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.1, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[0].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0.1, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[1].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0.1, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[2].self_time, 0.03 * @delta_multiplier)
  end

  def test_class_methods_threaded
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      background_thread = Thread.new do
        RubyProf::C1.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.1, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureWallTimeTest#test_class_methods_threaded', methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[0].children_time, 0.03 * @delta_multiplier)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].children_time, 0.03 * @delta_multiplier)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].children_time, 0.03 * @delta_multiplier)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].children_time, 0.03 * @delta_multiplier)

    thread = result.threads.last
    assert_in_delta(0.1, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureWallTimeTest#test_class_methods_threaded', methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[0].children_time, 0.03 * @delta_multiplier)

    assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[1].children_time, 0.03 * @delta_multiplier)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.1, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.1, methods[2].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].children_time, 0.03 * @delta_multiplier)
  end

  def test_instance_methods
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C1.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)
    names = methods.map(&:full_name)

    # order can differ
    assert(names.include?("BasicObject#initialize"))

    # Check times
    method = methods[0]
    assert_equal('MeasureWallTimeTest#test_instance_methods', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.self_time, 0.03 * @delta_multiplier)

    method = methods[1]
    assert_equal('RubyProf::C1#sleep_wait', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.self_time, 0.03 * @delta_multiplier)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, method.self_time, 0.03 * @delta_multiplier)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.self_time, 0.03 * @delta_multiplier)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, method.self_time, 0.03 * @delta_multiplier)
  end

  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
    def test_instance_methods_block
      result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
        1.times { RubyProf::C1.new.sleep_wait }
      end

      methods = result.threads.first.methods.sort.reverse
      assert_equal(6, methods.length)

      # Check times
      method = methods[0]
      assert_equal("MeasureWallTimeTest#test_instance_methods_block", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[1]
      assert_equal("Integer#times", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[2]
      assert_equal("RubyProf::C1#sleep_wait", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[3]
      assert_equal("Kernel#sleep", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[4]
      assert_equal("Class#new", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[5]
      assert_equal("BasicObject#initialize", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)
    end
  elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
    def test_instance_methods_block
      result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
        1.times { RubyProf::C1.new.sleep_wait }
      end

      methods = result.threads.first.methods.sort.reverse
      assert_equal(9, methods.length)

      # Check times
      method = methods[0]
      assert_equal("MeasureWallTimeTest#test_instance_methods_block", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[1]
      assert_equal("Integer#times", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[2]
      assert_equal("RubyProf::C1#sleep_wait", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[3]
      assert_equal("Kernel#sleep", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[4]
      assert_equal("Integer#succ", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[5]
      assert_equal("Class#new", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[6]
      assert_equal("Integer#<", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[7]
      assert_equal("Kernel#block_given?", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[8]
      assert_equal("BasicObject#initialize", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)
    end
  else
    def test_instance_methods_block
      result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
        1.times { RubyProf::C1.new.sleep_wait }
      end

      methods = result.threads.first.methods.sort.reverse
      assert_equal(9, methods.length)

      # Check times
      method = methods[0]
      assert_equal("MeasureWallTimeTest#test_instance_methods_block", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[1]
      assert_equal("Integer#times", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[2]
      assert_equal("RubyProf::C1#sleep_wait", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.children_time, 0.03 * @delta_multiplier)

      method = methods[3]
      assert_equal("Kernel#sleep", method.full_name)
      assert_in_delta(0.2, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.2, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[4]
      assert_equal("Kernel#block_given?", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[5]
      assert_equal("Integer#succ", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[6]
      assert_equal("Integer#<", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[7]
      assert_equal("Class#new", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

      method = methods[8]
      assert_equal("BasicObject#initialize", method.full_name)
      assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
      assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)
    end
  end

  def test_instance_methods_threaded
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      background_thread = Thread.new do
        RubyProf::C1.new.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureWallTimeTest#test_instance_methods_threaded', methods[0].full_name)
    assert_in_delta(0.2, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, methods[0].children_time, 0.03 * @delta_multiplier)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.2, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].children_time, 0.03 * @delta_multiplier)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].children_time, 0.03 * @delta_multiplier)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].children_time, 0.03 * @delta_multiplier)

    thread = result.threads.last
    assert_in_delta(0.2, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureWallTimeTest#test_instance_methods_threaded', methods[0].full_name)
    assert_in_delta(0.2, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, methods[0].children_time, 0.03 * @delta_multiplier)

    assert_equal('RubyProf::C1#sleep_wait', methods[1].full_name)
    assert_in_delta(0.2, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, methods[1].children_time, 0.03 * @delta_multiplier)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.2, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.2, methods[2].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].children_time, 0.03 * @delta_multiplier)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[3].children_time, 0.03 * @delta_multiplier)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[4].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[4].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[4].children_time, 0.03 * @delta_multiplier)
  end

  def test_module_methods
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C2.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    assert_equal('MeasureWallTimeTest#test_module_methods', methods[0].full_name)
    assert_equal('RubyProf::M1#sleep_wait', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[0].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0.3, methods[1].total_time, 0.1)
    assert_in_delta(0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[1].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0.3, methods[2].total_time, 0.1)
    assert_in_delta(0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.3, methods[2].self_time, 0.1)
  end

  def test_module_instance_methods
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C2.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)
    names = methods.map(&:full_name)
    assert_equal('MeasureWallTimeTest#test_module_instance_methods', names[0])
    assert_equal('RubyProf::M1#sleep_wait', names[1])
    assert_equal('Kernel#sleep', names[2])
    assert_equal('Class#new', names[3])

    # order can differ
    assert(names.include?("BasicObject#initialize"))

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.1)
    assert_in_delta(0, methods[0].self_time, 0.1)

    assert_in_delta(0.3, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[1].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0.3, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.3, methods[2].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0, methods[3].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[3].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[3].self_time, 0.03 * @delta_multiplier)

    assert_in_delta(0, methods[4].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[4].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0, methods[4].self_time, 0.03 * @delta_multiplier)
  end

  def test_singleton_methods
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      RubyProf::C3.instance.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.03 * @delta_multiplier)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(7, methods.length)

    assert_equal('MeasureWallTimeTest#test_singleton_methods', methods[0].full_name)
    assert_in_delta(0.3, methods[0].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[0].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.3, methods[0].children_time, 0.03 * @delta_multiplier)

    assert_equal('RubyProf::C3#sleep_wait', methods[1].full_name)
    assert_in_delta(0.3, methods[1].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[1].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.3, methods[1].children_time, 0.03 * @delta_multiplier)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.3, methods[2].total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.3, methods[2].self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, methods[2].children_time, 0.03 * @delta_multiplier)

    method = methods.detect {|a_method| a_method.full_name == 'Singleton::SingletonClassMethods#instance'}
    assert_equal('Singleton::SingletonClassMethods#instance', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

    method = methods.detect {|a_method| a_method.full_name == 'Thread::Mutex#synchronize'}
    assert_equal('Thread::Mutex#synchronize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

    method = methods.detect {|a_method| a_method.full_name == 'Class#new'}
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)

    method = methods.detect {|a_method| a_method.full_name == 'BasicObject#initialize'}
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.wait_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.self_time, 0.03 * @delta_multiplier)
    assert_in_delta(0.0, method.children_time, 0.03 * @delta_multiplier)
  end
end