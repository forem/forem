#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class DuplicateNamesTest < TestCase
  def test_names
    result = RubyProf::Profile.profile do
      str = %{module Foo; class Bar; def foo; end end end}

      eval str
      Foo::Bar.new.foo
      DuplicateNamesTest.class_eval {remove_const :Foo}

      eval str
      Foo::Bar.new.foo
      DuplicateNamesTest.class_eval {remove_const :Foo}

      eval str
      Foo::Bar.new.foo
    end

    # There should be 3 foo methods
    methods = result.threads.first.methods.sort.reverse

    methods = methods.select do |method|
      method.full_name == 'DuplicateNamesTest::Foo::Bar#foo'
    end

    assert_equal(3, methods.length)
  end
end
