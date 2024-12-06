#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class MeasureProcessTimeTest < TestCase
  def setup
    super
    GC.start
  end

  # These tests run to fast for Windows to detect any used process time
  if !windows?
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
      def test_class_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.08, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.06, method.self_time, 0.05)
        assert_in_delta(0.07, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.1, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.05, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.sleep_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(6, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_block", method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.11, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.11, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.busy_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(6, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_block", method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[3]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.11, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.11, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.2, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.1, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.1, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.15, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.15, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end
    elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
      def test_class_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.08, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.06, method.self_time, 0.05)
        assert_in_delta(0.07, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.1, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.05, method.children_time, 0.05)

        method = methods[2]
        assert('<Module::Process>#clock_gettime' == method.full_name ||
               'Float#<' == method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.sleep_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(6, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_block", method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.033, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.033, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.busy_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(8, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_block", method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[3]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.033, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.033, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.03, method.total_time, 0.03)
        assert_in_delta(0.03, method.wait_time, 0.03)
        assert_in_delta(0.03, method.self_time, 0.03)
        assert_in_delta(0.03, method.children_time, 0.03)

        method = methods[5]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.03, method.total_time, 0.03)
        assert_in_delta(0.03, method.wait_time, 0.03)
        assert_in_delta(0.03, method.self_time, 0.03)
        assert_in_delta(0.03, method.children_time, 0.03)

        method = methods[6]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.01)
        assert_in_delta(0.0, method.wait_time, 0.01)
        assert_in_delta(0.0, method.self_time, 0.01)
        assert_in_delta(0.0, method.children_time, 0.01)

        method = methods[7]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.2, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.1, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.03, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.03, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end
    else
      def test_class_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.08, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.06, method.self_time, 0.05)
        assert_in_delta(0.07, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_class_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.1, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.1, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[1]
        assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
        assert_in_delta(0.1, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.05, method.children_time, 0.05)

        method = methods[2]
        assert('<Module::Process>#clock_gettime' == method.full_name ||
                 'Float#<' == method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.sleep_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(9, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_block", method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#block_given?', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('Integer#succ', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Integer#<', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[7]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[8]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_sleep_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.sleep_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C1.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.033, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.033, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_block
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          1.times { RubyProf::C1.new.busy_wait }
        end

        methods = result.threads.first.methods.sort.reverse
        assert_equal(11, methods.length)

        # Check times
        method = methods[0]
        assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_block", method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Integer#times', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[2]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.09, method.self_time, 0.05)
        assert_in_delta(0.11, method.children_time, 0.05)

        method = methods[3]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.033, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.033, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.03, method.total_time, 0.03)
        assert_in_delta(0.03, method.wait_time, 0.03)
        assert_in_delta(0.03, method.self_time, 0.03)
        assert_in_delta(0.03, method.children_time, 0.03)

        method = methods[5]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.03, method.total_time, 0.03)
        assert_in_delta(0.03, method.wait_time, 0.03)
        assert_in_delta(0.03, method.self_time, 0.03)
        assert_in_delta(0.03, method.children_time, 0.03)

        method = methods[6]
        assert_equal('Kernel#block_given?', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[7]
        assert_equal('Integer#succ', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[8]
        assert_equal('Integer#<', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[9]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.01)
        assert_in_delta(0.0, method.wait_time, 0.01)
        assert_in_delta(0.0, method.self_time, 0.01)
        assert_in_delta(0.0, method.children_time, 0.01)

        method = methods[10]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_instance_methods_busy_threaded
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          background_thread = Thread.new do
            RubyProf::C1.new.busy_wait
          end
          background_thread.join
        end

        assert_equal(2, result.threads.count)

        thread = result.threads.first
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('Thread#join', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.2, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Class::Thread>#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Thread#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        thread = result.threads.last
        assert_in_delta(0.2, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(4, methods.length)

        methods = result.threads.last.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.2, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::C1#busy_wait', method.full_name)
        assert_in_delta(0.2, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.1, method.self_time, 0.05)
        assert_in_delta(0.1, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.03, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.03, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(3, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_sleep
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.sleep_wait
        end

        thread = result.threads.first
        assert_in_delta(0.0, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(5, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#sleep_wait', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[2]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_equal('Kernel#sleep', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end

      def test_module_instance_methods_busy
        result = RubyProf::Profile.profile(measure_mode: RubyProf::PROCESS_TIME) do
          RubyProf::C2.new.busy_wait
        end

        thread = result.threads.first
        assert_in_delta(0.3, thread.total_time, 0.05)

        methods = result.threads.first.methods.sort.reverse
        assert_equal(7, methods.length)

        # Check times
        method = methods[0]
        assert_equal('MeasureProcessTimeTest#test_module_instance_methods_busy', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.3, method.children_time, 0.05)

        method = methods[1]
        assert_equal('RubyProf::M1#busy_wait', method.full_name)
        assert_in_delta(0.3, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.15, method.self_time, 0.05)
        assert_in_delta(0.15, method.children_time, 0.05)

        method = methods[2]
        assert_equal('<Module::Process>#clock_gettime', method.full_name)
        assert_in_delta(0.05, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.05, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[3]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[4]
        assert_includes(['Float#<', 'Float#-'], method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[5]
        assert_equal('Class#new', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)

        method = methods[6]
        assert_equal('BasicObject#initialize', method.full_name)
        assert_in_delta(0.0, method.total_time, 0.05)
        assert_in_delta(0.0, method.wait_time, 0.05)
        assert_in_delta(0.0, method.self_time, 0.05)
        assert_in_delta(0.0, method.children_time, 0.05)
      end
    end
  end
end
