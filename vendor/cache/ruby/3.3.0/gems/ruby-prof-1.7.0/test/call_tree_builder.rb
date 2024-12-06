# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)
require 'base64'

# Create a DummyClass with methods so we can create call trees in the test_merge method below
class DummyClass
  %i[root a b aa ab ba bb].each do |method_name|
    define_method(method_name) do
    end
  end
end

def create_call_tree(method_name)
  method_info = RubyProf::MethodInfo.new(DummyClass, method_name)
  RubyProf::CallTree.new(method_info)
end

def build_call_tree(tree_hash)
  # tree_hash is a hash keyed on the parent method_name whose values are
  # child methods. Example:
  #
  # tree_hash = {:root => [:a, :b],
  #              :a => [:aa, :ab],
  #              :b => [:bb]}
  #
  # Note this is a simplified structure for testing. It assumes methods
  # are only called from one call_tree.

  call_trees = Hash.new
  tree_hash.each do |method_name, children|
    parent = call_trees[method_name] ||= create_call_tree(method_name)
    children.each do |child_method_name|
      child = call_trees[child_method_name] ||= create_call_tree(child_method_name)
      parent.add_child(child)
    end
  end

  call_trees
end

def create_call_tree_1
  #
  #          root    
  #        /     \   
  #       a       b  
  #     /  \       \ 
  #   aa   ab      bb
  #

  # ------ Call Trees 1 -------------
  tree_hash = {:root => [:a, :b],
               :a => [:aa, :ab],
               :b => [:bb]}

  call_trees = build_call_tree(tree_hash)

  # Setup times
  call_trees[:aa].measurement.total_time = 1.5
  call_trees[:aa].measurement.self_time = 1.5
  call_trees[:ab].measurement.total_time = 2.2
  call_trees[:ab].measurement.self_time = 2.2
  call_trees[:a].measurement.total_time = 3.7

  call_trees[:aa].target.measurement.total_time = 1.5
  call_trees[:aa].target.measurement.self_time = 1.5
  call_trees[:ab].target.measurement.total_time = 2.2
  call_trees[:ab].target.measurement.self_time = 2.2
  call_trees[:a].target.measurement.total_time = 3.7

  call_trees[:bb].measurement.total_time = 4.3
  call_trees[:bb].measurement.self_time = 4.3
  call_trees[:b].measurement.total_time = 4.3

  call_trees[:bb].target.measurement.total_time = 4.3
  call_trees[:bb].target.measurement.self_time = 4.3
  call_trees[:b].target.measurement.total_time = 4.3

  call_trees[:root].measurement.total_time = 8.0
  call_trees[:root].target.measurement.total_time = 8.0

  call_trees[:root]
end

def create_call_tree_2
  #
  #      root
  #    /     \
  #   a       b
  #    \     / \
  #    ab  ba  bb

  tree_hash = {:root => [:a, :b],
               :a => [:ab],
               :b => [:ba, :bb]}

  call_trees = build_call_tree(tree_hash)

  # Setup times
  call_trees[:ab].measurement.total_time = 0.4
  call_trees[:ab].measurement.self_time = 0.4
  call_trees[:a].measurement.total_time = 0.4

  call_trees[:ab].target.measurement.total_time = 0.4
  call_trees[:ab].target.measurement.self_time = 0.4
  call_trees[:a].target.measurement.total_time = 0.4

  call_trees[:ba].measurement.total_time = 0.9
  call_trees[:ba].measurement.self_time = 0.7
  call_trees[:ba].measurement.wait_time = 0.2
  call_trees[:bb].measurement.total_time = 2.3
  call_trees[:bb].measurement.self_time = 2.3
  call_trees[:b].measurement.total_time = 3.2

  call_trees[:ba].target.measurement.total_time = 0.9
  call_trees[:ba].target.measurement.self_time = 0.7
  call_trees[:ba].target.measurement.wait_time = 0.2
  call_trees[:bb].target.measurement.total_time = 2.3
  call_trees[:bb].target.measurement.self_time = 2.3
  call_trees[:b].target.measurement.total_time = 3.2

  call_trees[:root].measurement.total_time = 3.6
  call_trees[:root].target.measurement.total_time = 3.6

  call_trees[:root]
end
