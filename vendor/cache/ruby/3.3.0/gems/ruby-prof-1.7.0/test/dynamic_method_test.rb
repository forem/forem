#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path("../test_helper", __FILE__)

class DynamicMethodTest < TestCase

  class FruitMedley
    define_method(:apple) do
      sleep(0.1)
      "I'm a peach"
    end

    define_method(:orange) do
      sleep(0.2)
      "I'm an orange"
    end

    [:banana, :peach].each_with_index do |fruit,i|
      define_method(fruit) do
        sleep(i == 0 ? 0.3 : 0.4)
        "I'm a #{fruit}"
      end
    end
  end

  def test_dynamic_method
    medley = FruitMedley.new
    result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      medley.apple
      medley.orange
      medley.banana
      medley.peach
    end

    methods = result.threads.first.methods.sort.reverse

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
      expected_method_names = %w(
        DynamicMethodTest#test_dynamic_method
        Kernel#sleep
        DynamicMethodTest::FruitMedley#peach
        DynamicMethodTest::FruitMedley#banana
        DynamicMethodTest::FruitMedley#orange
        DynamicMethodTest::FruitMedley#apple
        Symbol#to_s
      )
    else
      expected_method_names = %w(
        DynamicMethodTest#test_dynamic_method
        Kernel#sleep
        DynamicMethodTest::FruitMedley#peach
        DynamicMethodTest::FruitMedley#banana
        DynamicMethodTest::FruitMedley#orange
        DynamicMethodTest::FruitMedley#apple
        Integer#==
      )
    end

    assert_equal expected_method_names.join("\n"), methods.map(&:full_name).join("\n")
  end
end
