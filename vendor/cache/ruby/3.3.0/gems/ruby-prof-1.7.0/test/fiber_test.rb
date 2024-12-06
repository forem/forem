#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fiber'
require 'timeout'
require 'set'

# --  Tests ----
class FiberTest < TestCase
  def enumerator_with_fibers
    enum = Enumerator.new do |yielder|
      [1,2].each do |x|
        yielder.yield x
      end
    end

    enum.next
    enum.next
  end

  def fiber_yield_resume
    fiber = Fiber.new do
              Fiber.yield 1
              Fiber.yield 2
            end

    fiber.resume
    fiber.resume
  end

  def test_fibers
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { enumerator_with_fibers }

    assert_equal(2, result.threads.size)

    thread1 = result.threads[0]
    methods = thread1.methods.sort.reverse
    assert_equal(5, methods.count)

    method = methods[0]
    assert_equal('FiberTest#test_fibers', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[1]
    assert_equal('FiberTest#enumerator_with_fibers', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[2]
    assert_equal('Enumerator#next', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[4]
    assert_equal('Enumerator#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    thread2 = result.threads[1]
    methods = thread2.methods.sort.reverse
    assert_equal(4, methods.count)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[0]
    assert_equal('Enumerator#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[1]
    assert_equal('Enumerator::Generator#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[2]
    assert_equal('Array#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[3]
    assert_equal('Enumerator::Yielder#yield', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)
  end

  def test_fiber_resume
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { fiber_yield_resume }

    assert_equal(2, result.threads.size)

    thread1 = result.threads[0]
    methods = thread1.methods.sort.reverse
    assert_equal(5, methods.count)

    method = methods[0]
    assert_equal('FiberTest#test_fiber_resume', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[1]
    assert_equal('FiberTest#fiber_yield_resume', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[2]
    assert_equal('Fiber#resume', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[4]
    assert_equal('Fiber#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    thread1 = result.threads[1]
    methods = thread1.methods.sort.reverse
    assert_equal(2, methods.count)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[0]
    assert_equal('FiberTest#fiber_yield_resume', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)

    method = methods[1]
    assert_equal('<Class::Fiber>#yield', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time)
    assert_in_delta(0, method.self_time)
    assert_in_delta(0, method.wait_time)
    assert_in_delta(0, method.children_time)
  end
end
