#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# --  Tests ----
class CallTreesTest < TestCase
  def some_method_1
    some_method_2
  end

  def some_method_2
  end

  def test_call_infos
    result = RubyProf::Profile.profile do
      some_method_1
    end

    thread = result.threads.first
    assert_equal(3, thread.methods.length)

    method = thread.methods[0]
    assert_equal('CallTreesTest#test_call_infos', method.full_name)

    call_trees = method.call_trees
    assert_empty(call_trees.callers)
    assert_equal(1, call_trees.callees.length)
    assert_kind_of(RubyProf::CallTree, call_trees.callees[0])
    assert_equal('CallTreesTest#some_method_1', call_trees.callees[0].target.full_name)

    method = thread.methods[1]
    assert_equal('CallTreesTest#some_method_1', method.full_name)

    call_trees = method.call_trees
    assert_equal(1, call_trees.callers.length)
    assert_kind_of(RubyProf::CallTree, call_trees.callers[0])
    assert_equal('CallTreesTest#test_call_infos', call_trees.callers[0].parent.target.full_name)
    assert_equal(1, call_trees.callees.length)
    assert_kind_of(RubyProf::CallTree, call_trees.callees[0])
    assert_equal('CallTreesTest#some_method_2', call_trees.callees[0].target.full_name)

    method = thread.methods[2]
    assert_equal('CallTreesTest#some_method_2', method.full_name)

    call_trees = method.call_trees
    assert_equal(1, call_trees.callers.length)
    assert_kind_of(RubyProf::CallTree, call_trees.callers[0])
    assert_equal('CallTreesTest#some_method_1', call_trees.callers[0].parent.target.full_name)
    assert_empty(call_trees.callees)
  end

  def test_gc
    result = RubyProf::Profile.profile do
      some_method_1
    end

    method = result.threads.first.methods[1]

    100.times do |i|
      method.call_trees.callers
      GC.start
    end
    assert(true)
  end
end
