#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class UniqueCallPath
  def method_a(i)
    if i==1
      method_b
    else
      method_c
    end
  end

  def method_b
    method_c
  end

  def method_c
  end

  def method_k(i)
    method_a(i)
  end
end


# --  Tests ----
class UniqueCallPathTest < TestCase
  def test_root
    unique_call_path = UniqueCallPath.new

    result = RubyProf::Profile.profile do
      unique_call_path.method_a(1)
    end

    root_call_info = result.threads.first.call_tree
    assert_equal("UniqueCallPathTest#test_root", root_call_info.target.full_name)
  end

  def test_root_children
    unique_call_path = UniqueCallPath.new

    result = RubyProf::Profile.profile do
      unique_call_path.method_a(1)
      unique_call_path.method_k(2)
    end

    root_call_info = result.threads.first.call_tree
    children = root_call_info.children.sort do |c1, c2|
      c1.target.full_name <=> c2.target.full_name
    end

    assert_equal(2, children.length)
    assert_equal("UniqueCallPath#method_a", children[0].target.full_name)
    assert_equal("UniqueCallPath#method_k", children[1].target.full_name)
  end

  def test_children_of
    unique_call_path = UniqueCallPath.new

    result = RubyProf::Profile.profile do
      unique_call_path.method_a(1)
      unique_call_path.method_k(2)
    end

    root_call_info = result.threads.first.call_tree
    assert_equal("UniqueCallPathTest#test_children_of", root_call_info.target.full_name)

    call_info_a = root_call_info.children.detect do |call_tree|
      call_tree.target.full_name == "UniqueCallPath#method_a"
    end
    refute_nil(call_info_a)

    _children_of_a = call_info_a.children.inject(Array.new) do |array, c|
      if c.parent.eql?(call_info_a)
        array << c
      end
      array
    end

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
      assert_equal(1, call_info_a.children.length)
      assert_equal("UniqueCallPath#method_b", call_info_a.children[0].target.full_name)
    else
      assert_equal(2, call_info_a.children.length)
      assert_equal("Integer#==", call_info_a.children[0].target.full_name)
      assert_equal("UniqueCallPath#method_b", call_info_a.children[1].target.full_name)
    end
  end

  def test_unique_path
    unique_call_path = UniqueCallPath.new

    result = RubyProf::Profile.profile do
      unique_call_path.method_a(1)
      unique_call_path.method_k(1)
    end

    root_call_info = result.threads.first.call_tree
    assert_equal("UniqueCallPathTest#test_unique_path", root_call_info.target.full_name)

    call_info_a = root_call_info.children.detect do |call_tree|
      call_tree.target.full_name == "UniqueCallPath#method_a"
    end
    refute_nil(call_info_a)

    children_of_a = call_info_a.children.reduce(Array.new) do |array, c|
      if c.parent.eql?(call_info_a)
        array << c
      end
      array
    end

    children_of_a = children_of_a.sort do |c1, c2|
      c1.target.full_name <=> c2.target.full_name
    end

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
      assert_equal(1, call_info_a.children.length)
      assert_equal(1, children_of_a.length)

      assert_equal(1, children_of_a[0].called)
      assert_equal("UniqueCallPath#method_b", children_of_a[0].target.full_name)
    else
      assert_equal(2, call_info_a.children.length)
      assert_equal(2, children_of_a.length)

      assert_equal(1, children_of_a[0].called)
      assert_equal("Integer#==", children_of_a[0].target.full_name)

      assert_equal(1, children_of_a[1].called)
      assert_equal("UniqueCallPath#method_b", children_of_a[1].target.full_name)
    end
  end
end
