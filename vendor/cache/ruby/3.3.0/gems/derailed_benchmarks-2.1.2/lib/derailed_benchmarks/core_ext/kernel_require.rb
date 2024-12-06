# frozen_string_literal: true

require 'get_process_mem'
require 'derailed_benchmarks/require_tree'

ENV['CUT_OFF'] ||= "0.3"

# This file contains classes and monkey patches to measure the amount of memory
# useage requiring an individual file adds.

# Monkey patch kernel to ensure that all `require` calls call the same
# method
module Kernel
  REQUIRE_STACK = []

  module_function

  alias_method :original_require, :require
  alias_method :original_require_relative, :require_relative
  alias_method(:original_load, :load)

  def load(file, wrap = false)
    measure_memory_impact(file) do |file|
      original_load(file)
    end
  end

  def require(file)
    measure_memory_impact(file) do |file|
      original_require(file)
    end
  end

  def require_relative(file)
    if Pathname.new(file).absolute?
      require file
    else
      require File.expand_path("../#{file}", caller_locations(1, 1)[0].absolute_path)
    end
  end

  private

  # The core extension we use to measure require time of all requires
  # When a file is required we create a tree node with its file name.
  # We then push it onto a stack, this is because requiring a file can
  # require other files before it is finished.
  #
  # When a child file is required, a tree node is created and the child file
  # is pushed onto the parents tree. We then repeat the process as child
  # files may require additional files.
  #
  # When a require returns we remove it from the require stack so we don't
  # accidentally push additional children nodes to it. We then store the
  # memory cost of the require in the tree node.
  def measure_memory_impact(file, &block)
    mem    = GetProcessMem.new
    node   = DerailedBenchmarks::RequireTree.new(file)

    parent = REQUIRE_STACK.last
    parent << node
    REQUIRE_STACK.push(node)
    begin
      before = mem.mb
      block.call file
    ensure
      REQUIRE_STACK.pop # node
      after = mem.mb
    end
    node.cost = after - before
  end
end


# I honestly have no idea why this Object delegation is needed
# I keep staring at bootsnap and it doesn't have to do this
# is there a bug in their implementation they haven't caught or
# am I doing something different?
class Object
  private
  def load(path, wrap = false)
    Kernel.load(path, wrap)
  end

  def require(path)
    Kernel.require(path)
  end
end

# Top level node that will store all require information for the entire app
TOP_REQUIRE = DerailedBenchmarks::RequireTree.new("TOP")
REQUIRE_STACK.push(TOP_REQUIRE)
TOP_REQUIRE.cost = GetProcessMem.new.mb

def TOP_REQUIRE.print_sorted_children(*args)
  self.cost = GetProcessMem.new.mb - self.cost
  super
end

