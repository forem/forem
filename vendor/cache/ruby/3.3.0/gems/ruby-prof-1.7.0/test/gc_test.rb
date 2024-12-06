#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
Minitest::Test.i_suck_and_my_tests_are_order_dependent!

class GcTest < TestCase
  def setup
    super
    GC.stress = true
  end

  def teardown
    GC.stress = false
  end

  def some_method
    Array.new(3 * 4)
  end

  def run_profile
    RubyProf::Profile.profile do
      self.some_method
    end
  end

  def test_hold_onto_thread
    threads = 5.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads)
      array
    end

    GC.start

    threads.each do |thread|
      refute_nil(thread.id)
    end
  end

  def test_hold_onto_method
    methods = 5.times.reduce(Array.new) do |array, i|
      profile = run_profile
      array.concat(profile.threads.map(&:methods).flatten)
      array
    end

    GC.start

    methods.each do |method|
      refute_nil(method.method_name)
    end
  end

  def test_hold_onto_call_trees
    method_call_infos = 5.times.reduce(Array.new) do |array, i|
      profile = run_profile
      call_trees = profile.threads.map(&:methods).flatten.map(&:call_trees).flatten
      array.concat(call_trees)
      array
    end

    GC.start

    method_call_infos.each do |call_trees|
      refute_empty(call_trees.call_trees)
    end
  end

  def test_hold_onto_measurements
    # Run a profile
    profile = run_profile

    # Get measurement objects
    measurements = profile.threads.map(&:methods).flatten.map(&:measurement)

    # Free the profiles which frees the measurements
    profile = nil

    GC.start

    measurements.each_with_index do |measurement|
      error = assert_raises(RuntimeError) do
        measurement.total_time
      end
      assert_match(/RubyProf::Measurement instance has already been freed/, error.message)
    end
    assert(true)
  end

  def test_hold_onto_root_call_tree
    call_trees = 5.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:call_tree))
      array
    end

    GC.start

    call_trees.each do |call_tree|
      refute_nil(call_tree.source_file)
    end
  end
end
