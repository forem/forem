#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'timeout'
require 'benchmark'
require_relative './call_tree_builder'

# --  Tests ----
class ThreadTest < TestCase
  def test_initialize
    method_info = RubyProf::MethodInfo.new(Array, :size)
    call_tree = RubyProf::CallTree.new(method_info)
    thread = RubyProf::Thread.new(call_tree, Thread.current, Fiber.current)

    assert_equal(call_tree, thread.call_tree)
    assert(thread)
    assert(thread.id)
    assert(thread.fiber_id)

    assert_equal(1, thread.methods.size)
    assert_same(method_info, thread.methods[0])
  end

  def test_merge
    call_tree_1 = create_call_tree_1
    thread_1 = RubyProf::Thread.new(call_tree_1, Thread.current, Fiber.current)
    assert_equal(6, thread_1.methods.size)

    call_tree_2 = create_call_tree_2
    thread_2 = RubyProf::Thread.new(call_tree_2, Thread.current, Fiber.current)
    assert_equal(6, thread_2.methods.size)

    thread_1.merge!(thread_2)
    assert_equal(7, thread_1.methods.size)

    # Method times
    assert_in_delta(11.6, thread_1.methods[0].total_time, 0.00001) # root
    assert_in_delta(4.1, thread_1.methods[1].total_time, 0.00001)  # a
    assert_in_delta(1.5, thread_1.methods[2].total_time, 0.00001)  # aa
    assert_in_delta(2.6, thread_1.methods[3].total_time, 0.00001)  # ab
    assert_in_delta(7.5, thread_1.methods[4].total_time, 0.00001)  # b
    assert_in_delta(6.6, thread_1.methods[5].total_time, 0.00001)  # bb
    assert_in_delta(0.9, thread_1.methods[6].total_time, 0.00001)  # ba

    # Root
    call_tree = call_tree_1
    assert_equal(:root, call_tree.target.method_name)
    assert_in_delta(11.6, call_tree.total_time, 0.00001)
    assert_in_delta(0, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(11.6, call_tree.children_time, 0.00001)

    # a
    call_tree = call_tree_1.children[0]
    assert_equal(:a, call_tree.target.method_name)
    assert_in_delta(4.1, call_tree.total_time, 0.00001)
    assert_in_delta(0, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(4.1, call_tree.children_time, 0.00001)

    # aa
    call_tree = call_tree_1.children[0].children[0]
    assert_equal(:aa, call_tree.target.method_name)
    assert_in_delta(1.5, call_tree.total_time, 0.00001)
    assert_in_delta(1.5, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    # ab
    call_tree = call_tree_1.children[0].children[1]
    assert_equal(:ab, call_tree.target.method_name)
    assert_in_delta(2.6, call_tree.total_time, 0.00001)
    assert_in_delta(2.6, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    # # b
    # call_tree = call_tree_1.children[1]
    # assert_equal(:b, call_tree.target.method_name)
    # assert_in_delta(7.5, call_tree.total_time, 0.00001)
    # assert_in_delta(0, call_tree.self_time, 0.00001)
    # assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    # assert_in_delta(7.5, call_tree.children_time, 0.00001)

    # bb
    # call_tree = call_tree_1.children[1].children[0]
    # assert_equal(:bb, call_tree.target.method_name)
    # assert_in_delta(6.6, call_tree.total_time, 0.00001)
    # assert_in_delta(6.6, call_tree.self_time, 0.00001)
    # assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    # assert_in_delta(0.0, call_tree.children_time, 0.00001)

    # ba
    call_tree = call_tree_1.children[1].children[1]
    assert_equal(:ba, call_tree.target.method_name)
    assert_in_delta(0.9, call_tree.total_time, 0.00001)
    assert_in_delta(0.7, call_tree.self_time, 0.00001)
    assert_in_delta(0.2, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)
  end

  def test_thread_count
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      thread = Thread.new do
        sleep(1)
      end

      thread.join
    end
    assert_equal(2, result.threads.length)
  end

  def test_thread_identity
    profile = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)
    profile.start

    sleep_thread = Thread.new do
      sleep(1)
    end
    sleep_thread.join
    result = profile.stop

    thread_ids = result.threads.map {|thread| thread.id}.sort
    threads = [Thread.current, sleep_thread]
    assert_equal(2, result.threads.length)

    assert(thread_ids.include?(threads[0].object_id))
    assert(thread_ids.include?(threads[1].object_id))

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[0]))
    assert(threads.include?(ObjectSpace._id2ref(thread_ids[0])))

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[1]))
    assert(threads.include?(ObjectSpace._id2ref(thread_ids[1])))
  end

  def test_thread_timings
    profile = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)
    profile.start

    thread = Thread.new do
      sleep 0
      # force it to hit thread.join, below, first
      # thus forcing sleep(1), below, to be counted as (wall) self_time
      # since we currently count time "in some other thread" as self.wait_time
      sleep(1)
    end
    thread.join
    result = profile.stop

    # Check background thread
    assert_equal(2, result.threads.length)

    rp_thread = result.threads.detect {|t| t.id == thread.object_id}
    methods = rp_thread.methods.sort.reverse

    method = methods[0]
    assert_equal('ThreadTest#test_thread_timings', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(1, method.children_time, 0.1)
    assert_equal(0, method.call_trees.callers.length)

    method = methods[1]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(1, method.total_time, 0.05)
    assert_in_delta(1.0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callers.length)
    assert_equal(0, method.call_trees.callees.length)

    # Check foreground thread
    rp_thread = result.threads.detect {|athread| athread.id == Thread.current.object_id}
    methods = rp_thread.methods.sort.reverse
    assert_equal(4, methods.length)
    methods = methods.sort.reverse

    method = methods[0]
    assert_equal('ThreadTest#test_thread_timings', method.full_name)
    # the sub calls to Object#new, when popped,
    # cause the parent frame to be created for method #test_thread_timings, which means a +1 when it's popped in the end
    # xxxx a test that shows it the other way, too (never creates parent frame--if that's even possible)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(1, method.children_time, 0.05)

    assert_equal(0, method.call_trees.callers.length)
    assert_equal(2, method.call_trees.callees.length)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(1.0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callers.length)
    assert_equal(0, method.call_trees.callees.length)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callers.length)
    assert_equal(1, method.call_trees.callees.length)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callers.length)
    assert_equal(0, method.call_trees.callees.length)
  end
end
