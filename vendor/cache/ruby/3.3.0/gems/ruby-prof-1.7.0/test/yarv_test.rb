#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# tests for bugs reported by users
class YarvTest < TestCase
  def setup
    super
    define_methods
  end

  def test_array_push_unoptimized
    a = nil
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      a = self.array_push_unoptimized
    end
    assert_equal 2, a.length
    assert_equal ["YarvTest#test_array_push_unoptimized", "YarvTest#array_push_unoptimized", 'Array#<<', "Array#push"], result.threads.first.methods.map(&:full_name)
  end

  def test_array_push_optimized
    a = nil
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      a = self.array_push_optimized
    end
    assert_equal(2, a.length)
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
      assert_equal(["YarvTest#test_array_push_optimized", "YarvTest#array_push_optimized", "Array#push"], result.threads.first.methods.map(&:full_name))
    else
      assert_equal(["YarvTest#test_array_push_optimized", "YarvTest#array_push_optimized", "Array#<<", "Array#push"], result.threads.first.methods.map(&:full_name))
    end
  end

  private

  def define_methods
    return if respond_to?(:array_push_optimized)
    old_compile_option = RubyVM::InstructionSequence.compile_option
    RubyVM::InstructionSequence.compile_option = {
      :trace_instruction => true,
      :specialized_instruction => false
    }
    self.class.class_eval <<-"EOM"
      def array_push_unoptimized
        a = []
        a << 1
        a.push 2
      end
    EOM
    RubyVM::InstructionSequence.compile_option = old_compile_option
    self.class.class_eval <<-"EOM"
      def array_push_optimized
        a = []
        a << 1
        a.push 2
      end
    EOM
  end
end
