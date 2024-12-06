#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

module ExcludeMethodsModule
  def c
    1.times { |i| ExcludeMethodsModule.d }
  end

  def self.d
    1.times { |i| ExcludeMethodsClass.e }
  end
end

class ExcludeMethodsClass
  include ExcludeMethodsModule

  def a
    1.times { |i| b }
  end

  def b
    1.times { |i| c; self.class.e }
  end

  def self.e
    1.times { |i| f }
  end

  def self.f
    sleep 0.1
  end
end

class ExcludeMethodsTest < TestCase
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
    def test_methods_can_be_profiled
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse
      assert_equal(10, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_profiled', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('Integer#times', methods[2].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[4].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[5].full_name)
      assert_equal('Kernel#sleep', methods[6].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[7].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[8].full_name)
      assert_equal('Kernel#class', methods[9].full_name)
    end

    def test_methods_can_be_hidden1
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new

      prf.exclude_methods!(Integer, :times)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(9, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_hidden1', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[4].full_name)
      assert_equal('Kernel#sleep', methods[5].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[6].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[7].full_name)
      assert_equal('Kernel#class', methods[8].full_name)
    end

    def test_methods_can_be_hidden2
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new

      prf.exclude_methods!(Integer, :times)
      prf.exclude_methods!(ExcludeMethodsClass.singleton_class, :f)
      prf.exclude_methods!(ExcludeMethodsModule.singleton_class, :d)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(7, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_hidden2', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('Kernel#sleep', methods[4].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[5].full_name)
      assert_equal('Kernel#class', methods[6].full_name)
    end

    def test_exclude_common_methods1
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)

      prf.exclude_common_methods!

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(9, methods.count)
      assert_equal('ExcludeMethodsTest#test_exclude_common_methods1', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[4].full_name)
      assert_equal('Kernel#sleep', methods[5].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[6].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[7].full_name)
      assert_equal('Kernel#class', methods[8].full_name)
    end

    def test_exclude_common_methods2
      obj = ExcludeMethodsClass.new

      result = RubyProf::Profile.profile(exclude_common: true) { 5.times {obj.a} }
      methods = result.threads.first.methods.sort.reverse

      assert_equal(9, methods.count)
      assert_equal('ExcludeMethodsTest#test_exclude_common_methods2', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
    end
  else
    def test_methods_can_be_profiled
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse
      assert_equal(13, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_profiled', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('Integer#times', methods[2].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[4].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[5].full_name)
      assert_equal('Kernel#sleep', methods[6].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[7].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[8].full_name)
      assert_equal('Kernel#block_given?', methods[9].full_name)
      assert_equal('Integer#succ', methods[10].full_name)
      assert_equal('Integer#<', methods[11].full_name)
      assert_equal('Kernel#class', methods[12].full_name)
    end

    def test_methods_can_be_hidden1
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new

      prf.exclude_methods!(Integer, :times)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(12, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_hidden1', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[4].full_name)
      assert_equal('Kernel#sleep', methods[5].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[6].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[7].full_name)
      assert_equal('Kernel#block_given?', methods[8].full_name)
      assert_equal('Integer#succ', methods[9].full_name)
      assert_equal('Integer#<', methods[10].full_name)
      assert_equal('Kernel#class', methods[11].full_name)
    end

    def test_methods_can_be_hidden2
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new

      prf.exclude_methods!(Integer, :times)
      prf.exclude_methods!(ExcludeMethodsClass.singleton_class, :f)
      prf.exclude_methods!(ExcludeMethodsModule.singleton_class, :d)

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(10, methods.count)
      assert_equal('ExcludeMethodsTest#test_methods_can_be_hidden2', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('Kernel#sleep', methods[4].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[5].full_name)
      assert_equal('Kernel#block_given?', methods[6].full_name)
      assert_equal('Integer#succ', methods[7].full_name)
      assert_equal('Integer#<', methods[8].full_name)
      assert_equal('Kernel#class', methods[9].full_name)
    end

    def test_exclude_common_methods1
      obj = ExcludeMethodsClass.new
      prf = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)

      prf.exclude_common_methods!

      result = prf.profile {obj.a}
      methods = result.threads.first.methods.sort.reverse

      assert_equal(9, methods.count)
      assert_equal('ExcludeMethodsTest#test_exclude_common_methods1', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[4].full_name)
      assert_equal('Kernel#sleep', methods[5].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[6].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[7].full_name)
      assert_equal('Kernel#class', methods[8].full_name)
    end

    def test_exclude_common_methods2
      obj = ExcludeMethodsClass.new

      result = RubyProf::Profile.profile(exclude_common: true) { 5.times {obj.a} }
      methods = result.threads.first.methods.sort.reverse

      assert_equal(9, methods.count)
      assert_equal('ExcludeMethodsTest#test_exclude_common_methods2', methods[0].full_name)
      assert_equal('ExcludeMethodsClass#a', methods[1].full_name)
      assert_equal('ExcludeMethodsClass#b', methods[2].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#e', methods[3].full_name)
      assert_equal('<Class::ExcludeMethodsClass>#f', methods[4].full_name)
      assert_equal('Kernel#sleep', methods[5].full_name)
      assert_equal('ExcludeMethodsModule#c', methods[6].full_name)
      assert_equal('<Module::ExcludeMethodsModule>#d', methods[7].full_name)
      assert_equal('Kernel#class', methods[8].full_name)
    end
  end

  private

  def assert_method_has_been_excluded(result, excluded_method)
    result.threads.each do |thread|
      thread.methods.each do |method|
        method.call_trees.each do |ci|
          assert(ci.target != excluded_method, "broken self")
          assert(ci.parent.target != excluded_method, "broken parent") if ci.parent
          ci.children.each do |callee|
            assert(callee.target != excluded_method, "broken kid")
          end
        end
      end
    end
  end
end
