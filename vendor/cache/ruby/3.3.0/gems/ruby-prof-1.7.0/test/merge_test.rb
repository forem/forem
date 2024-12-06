#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1.0')

require_relative './scheduler'

  # --  Tests ----
class MergeTest < TestCase
  def worker1
    sleep(0.5)
  end

  def worker2
    sleep(0.5)
    sleep(0.5)
  end

  def worker3
    sleep(0.5)
  end

  def concurrency_single_worker
    scheduler = Scheduler.new
    Fiber.set_scheduler(scheduler)

    3.times do
      Fiber.schedule do
        worker1
      end
    end
    Fiber.scheduler.close
  end

  def concurrency_multiple_workers
    scheduler = Scheduler.new
    Fiber.set_scheduler(scheduler)

    3.times do |i|
      Fiber.schedule do
        method = "worker#{i + 1}".to_sym
        send(method)
      end
    end
    Fiber.scheduler.close
  end

  def test_single_worker_unmerged
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_single_worker }
    assert_equal(4, result.threads.size)

    thread = result.threads[0]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[1]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[2]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[3]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)
  end

  def test_single_worker_merged
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_single_worker }
    result.merge!

    assert_equal(2, result.threads.size)

    thread = result.threads[0]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[1]
    assert_in_delta(1.5, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(1.5, thread.call_tree.target.children_time, 0.1)
  end

  def test_multiple_workers_unmerged
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_multiple_workers }
    assert_equal(4, result.threads.count)

    thread = result.threads[0]
    assert_in_delta(1.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(1.0, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[1]
    assert_in_delta(1.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[2]
    assert_in_delta(1.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(1.0, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[3]
    assert_in_delta(1.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.1)
  end

  def test_multiple_workers_merged
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_multiple_workers }
    result.merge!

    assert_equal(2, result.threads.count)

    thread = result.threads[0]
    assert_in_delta(1.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(1.0, thread.call_tree.target.children_time, 0.1)

    thread = result.threads[1]
    assert_in_delta(3.0, thread.call_tree.target.total_time, 0.1)
    assert_in_delta(0.0, thread.call_tree.target.self_time, 0.1)
    assert_in_delta(1.0, thread.call_tree.target.wait_time, 0.1)
    assert_in_delta(2.0, thread.call_tree.target.children_time, 0.1)
  end
end
end
