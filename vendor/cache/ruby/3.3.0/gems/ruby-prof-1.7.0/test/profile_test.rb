#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './call_tree_builder'

class ProfileTest < TestCase
  def test_measure_mode
    profile = RubyProf::Profile.new(:measure_mode => RubyProf::PROCESS_TIME)
    assert_equal(RubyProf::PROCESS_TIME, profile.measure_mode)
  end

  def test_measure_mode_string
    profile = RubyProf::Profile.new(:measure_mode => RubyProf::PROCESS_TIME)
    assert_equal("process_time", profile.measure_mode_string)
  end

  def test_add_thread
    profile = RubyProf::Profile.new
    assert_empty(profile.threads)

    method_info = RubyProf::MethodInfo.new(Array, :size)
    call_tree = RubyProf::CallTree.new(method_info)
    thread = RubyProf::Thread.new(call_tree, Thread.current, Fiber.current)

    profile.add_thread(thread)
    assert_equal(1, profile.threads.size)
    assert(thread.equal?(profile.threads.first))
  end

  def test_add_threads
    call_tree_1 = create_call_tree_1
    ruby_thread_1 = Thread.new { }
    thread_1 = RubyProf::Thread.new(call_tree_1, ruby_thread_1, Fiber.current)

    call_tree_2 = create_call_tree_2
    ruby_thread_2 = Thread.new { }
    thread_2 = RubyProf::Thread.new(call_tree_2, ruby_thread_2, Fiber.current)

    profile = RubyProf::Profile.new
    profile.add_thread(thread_1)
    profile.add_thread(thread_2)
    assert_equal(1, profile.threads.count)
  end

  def test_add_fibers
    call_tree_1 = create_call_tree_1
    fiber_1 = Fiber.new { }
    thread_1 = RubyProf::Thread.new(call_tree_1, Thread.current, fiber_1)

    call_tree_2 = create_call_tree_2
    fiber_2 = Fiber.new { }
    thread_2 = RubyProf::Thread.new(call_tree_2, Thread.current, fiber_2)

    profile = RubyProf::Profile.new
    profile.add_thread(thread_1)
    profile.add_thread(thread_2)
    assert_equal(2, profile.threads.count)
  end

  def test_remove_thread
    profile = RubyProf::Profile.new
    assert_empty(profile.threads)

    method_info = RubyProf::MethodInfo.new(Array, :size)
    call_tree = RubyProf::CallTree.new(method_info)
    thread = RubyProf::Thread.new(call_tree, Thread.current, Fiber.current)

    profile.add_thread(thread)
    assert_equal(1, profile.threads.size)
    assert(thread.equal?(profile.threads.first))

    removed = profile.remove_thread(thread)
    assert_equal(0, profile.threads.size)
    assert(removed.equal?(thread))
  end

  def test_merge
    call_tree_1 = create_call_tree_1
    fiber_1 = Thread.new { }
    thread_1 = RubyProf::Thread.new(call_tree_1, Thread.current, fiber_1)

    call_tree_2 = create_call_tree_2
    fiber_2 = Thread.new { }
    thread_2 = RubyProf::Thread.new(call_tree_2, Thread.current, fiber_2)

    profile = RubyProf::Profile.new
    profile.add_thread(thread_1)
    profile.add_thread(thread_2)

    profile.merge!
    assert_equal(1, profile.threads.count)

    assert_equal(thread_1, profile.threads.first)

    assert_in_delta(11.6, thread_1.call_tree.total_time, 0.00001)
    assert_in_delta(0, thread_1.call_tree.self_time, 0.00001)
    assert_in_delta(0.0, thread_1.call_tree.wait_time, 0.00001)
    assert_in_delta(11.6, thread_1.call_tree.children_time, 0.00001)
  end
end
