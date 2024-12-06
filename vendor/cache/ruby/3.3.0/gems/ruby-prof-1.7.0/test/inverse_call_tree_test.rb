#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class InverseCallTreeTest < TestCase
  def setup
    super
    @profile = RubyProf::Profile.new
  end
  INVERSE_DEPTH = 5

  INVERSE_DEPTH.times do |i|
    if i == 0
      define_method("method_#{i}") do
        sleep_amount = (i + 1) * 0.05
        @profile.start
        sleep(sleep_amount)
      end
    else
      define_method("method_#{i}") do
        method_name = "method_#{i-1}"
        sleep_amount = (i + 1) * 0.05
        self.send(method_name.to_sym)
        sleep(sleep_amount)
      end
    end
  end

  def test_inverse
    method_name = "method_#{INVERSE_DEPTH - 1}"
    self.send(method_name.to_sym)
    result = @profile.stop

    assert_equal(1, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.79, thread.total_time, 0.05)

    assert_equal(7, thread.methods.length)
    methods = thread.methods.sort.reverse

    # InverseCallTreeTest#test_inverse
    method = methods[0]
    assert_equal('InverseCallTreeTest#test_inverse', method.full_name)
    assert_equal(33, method.line)

    assert_equal(0, method.call_trees.callers.count)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('InverseCallTreeTest#method_4', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    # InverseCallTreeTest#method_4
    method = methods[1]
    assert_equal('InverseCallTreeTest#method_4', method.full_name)
    assert_equal(25, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#test_inverse', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('InverseCallTreeTest#method_3', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    # Kernel#sleep
    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(0, method.line)

    assert_equal(5, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#method_0', call_tree.parent.target.full_name)
    assert_equal(18, call_tree.line)

    call_tree = method.call_trees.callers[1]
    assert_equal('InverseCallTreeTest#method_1', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    call_tree = method.call_trees.callers[2]
    assert_equal('InverseCallTreeTest#method_2', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)
    call_tree = method.call_trees.callers[3]

    assert_equal('InverseCallTreeTest#method_3', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    call_tree = method.call_trees.callers[4]
    assert_equal('InverseCallTreeTest#method_4', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    assert_equal(0, method.call_trees.callees.count)

    # InverseCallTreeTest#method_3
    method = methods[3]
    assert_equal('InverseCallTreeTest#method_3', method.full_name)
    assert_equal(25, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#method_4', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('InverseCallTreeTest#method_2', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    # InverseCallTreeTest#method_2
    method = methods[4]
    assert_equal('InverseCallTreeTest#method_2', method.full_name)
    assert_equal(25, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#method_3', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('InverseCallTreeTest#method_1', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    # InverseCallTreeTest#method_1
    method = methods[5]
    assert_equal('InverseCallTreeTest#method_1', method.full_name)
    assert_equal(25, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#method_2', call_tree.parent.target.full_name)
    assert_equal(25, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('InverseCallTreeTest#method_0', call_tree.target.full_name)
    assert_equal(18, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(25, call_tree.line)

    # InverseCallTreeTest#method_0
    method = methods[6]
    assert_equal('InverseCallTreeTest#method_0', method.full_name)
    assert_equal(18, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('InverseCallTreeTest#method_1', call_tree.parent.target.full_name)
    assert_equal(18, call_tree.line)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(18, call_tree.line)
  end
end
