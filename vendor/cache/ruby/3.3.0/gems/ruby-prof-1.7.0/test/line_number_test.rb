#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class LineNumbers
  def method_1
    method_2
    _filler = 1
    method_3
  end

  def method_2
    _filler = 1
    2.times do |i|
      _filler = 2
      method_3
    end
  end

  def method_3
    method_4
  end

  def method_4
  end
end

# --  Tests ----
class LineNumbersTest < TestCase
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
    def test_function_line_no
      numbers = LineNumbers.new

      result = RubyProf::Profile.profile do
        numbers.method_1
      end

      # Sort methods by name to have stable results
      methods = result.threads.first.methods.sort_by(&:full_name)
      assert_equal(6, methods.length)

      # Method 0
      method = methods[0]
      assert_equal('Integer#times', method.full_name)
      assert_equal(0, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_2', call_tree.parent.target.full_name)
      assert_equal(15, call_tree.line)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_3', call_tree.target.full_name)
      assert_equal(17, call_tree.line)

      # Method 1
      method = methods[1]
      assert_equal('LineNumbers#method_1', method.full_name)
      assert_equal(7, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbersTest#test_function_line_no', call_tree.parent.target.full_name)
      assert_equal(36, call_tree.line)

      assert_equal(2, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_2', call_tree.target.full_name)
      assert_equal(8, call_tree.line)

      call_tree = method.call_trees.callees[1]
      assert_equal('LineNumbers#method_3', call_tree.target.full_name)
      assert_equal(10, call_tree.line)

      # Method 2
      method = methods[2]
      assert_equal('LineNumbers#method_2', method.full_name)
      assert_equal(13, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
      assert_equal(8, call_tree.line)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#times', call_tree.target.full_name)
      assert_equal(15, call_tree.line)

      # Method 3
      method = methods[3]
      assert_equal('LineNumbers#method_3', method.full_name)
      assert_equal(21, method.line)

      assert_equal(2, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(17, call_tree.line)

      call_tree = method.call_trees.callers[1]
      assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.line)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_4', call_tree.target.full_name)
      assert_equal(22, call_tree.line)

      # Method 4
      method = methods[4]
      assert_equal('LineNumbers#method_4', method.full_name)
      assert_equal(25, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_3', call_tree.parent.target.full_name)
      assert_equal(22, call_tree.line)

      assert_equal(0, method.call_trees.callees.count)

      # Method 5
      method = methods[5]
      assert_equal('LineNumbersTest#test_function_line_no', method.full_name)
      assert_equal(36, method.line)

      assert_equal(0, method.call_trees.callers.count)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_1', call_tree.target.full_name)
      assert_equal(36, call_tree.line)
    end
  else
    def test_function_line_no
      numbers = LineNumbers.new

      result = RubyProf::Profile.profile do
        numbers.method_1
      end

      # Sort methods by name to have stable results
      methods = result.threads.first.methods.sort_by(&:full_name)
      assert_equal(9, methods.length)

      # Method 0
      method = methods[0]
      assert_equal('Integer#<', method.full_name)
      assert_equal(0, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(236, call_tree.line)

      assert_equal(0, method.call_trees.callees.count)

      # Method 1
      method = methods[1]
      assert_equal('Integer#succ', method.full_name)
      assert_equal(0, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(238, call_tree.line)

      assert_equal(0, method.call_trees.callees.count)

      # Method 2
      method = methods[2]
      assert_equal('Integer#times', method.full_name)
      assert_equal(231, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_2', call_tree.parent.target.full_name)
      assert_equal(15, call_tree.line)

      assert_equal(4, method.call_trees.callees.count)

      call_tree = method.call_trees.callees[0]
      assert_equal('Kernel#block_given?', call_tree.target.full_name)
      assert_equal(232, call_tree.line)

      call_tree = method.call_trees.callees[1]
      assert_equal('Integer#<', call_tree.target.full_name)
      assert_equal(236, call_tree.line)

      call_tree = method.call_trees.callees[2]
      assert_equal('LineNumbers#method_3', call_tree.target.full_name)
      assert_equal(17, call_tree.line)

      call_tree = method.call_trees.callees[3]
      assert_equal('Integer#succ', call_tree.target.full_name)
      assert_equal(238, call_tree.line)

      # Method 3
      method = methods[3]
      assert_equal('Kernel#block_given?', method.full_name)
      assert_equal(0, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(232, call_tree.line)

      assert_equal(0, method.call_trees.callees.count)

      # Method 4
      method = methods[4]
      assert_equal('LineNumbers#method_1', method.full_name)
      assert_equal(7, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbersTest#test_function_line_no', call_tree.parent.target.full_name)
      assert_equal(140, call_tree.line)

      assert_equal(2, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_2', call_tree.target.full_name)
      assert_equal(8, call_tree.line)

      call_tree = method.call_trees.callees[1]
      assert_equal('LineNumbers#method_3', call_tree.target.full_name)
      assert_equal(10, call_tree.line)

      # Method 5
      method = methods[5]
      assert_equal('LineNumbers#method_2', method.full_name)
      assert_equal(13, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
      assert_equal(8, call_tree.line)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#times', call_tree.target.full_name)
      assert_equal(15, call_tree.line)

      # Method 6
      method = methods[6]
      assert_equal('LineNumbers#method_3', method.full_name)
      assert_equal(21, method.line)

      assert_equal(2, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(17, call_tree.line)

      call_tree = method.call_trees.callers[1]
      assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.line)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_4', call_tree.target.full_name)
      assert_equal(22, call_tree.line)

      # Method 7
      method = methods[7]
      assert_equal('LineNumbers#method_4', method.full_name)
      assert_equal(25, method.line)

      assert_equal(1, method.call_trees.callers.count)
      call_tree = method.call_trees.callers[0]
      assert_equal('LineNumbers#method_3', call_tree.parent.target.full_name)
      assert_equal(22, call_tree.line)

      assert_equal(0, method.call_trees.callees.count)

      # Method 8
      method = methods[8]
      assert_equal('LineNumbersTest#test_function_line_no', method.full_name)
      assert_equal(140, method.line)

      assert_equal(0, method.call_trees.callers.count)

      assert_equal(1, method.call_trees.callees.count)
      call_tree = method.call_trees.callees[0]
      assert_equal('LineNumbers#method_1', call_tree.target.full_name)
      assert_equal(140, call_tree.line)
    end
  end
end
