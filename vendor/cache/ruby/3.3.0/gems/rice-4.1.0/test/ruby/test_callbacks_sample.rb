$: << File.join(File.dirname(__FILE__), '..', 'sample')

require 'rubygems'
gem 'minitest'
require 'minitest/autorun'
require_relative '../../sample/callbacks/sample_callbacks'

class CallbacksTest < Minitest::Test
  def test_callbacks_sample_lambda
    cb = CallbackHolder.new
    cb.register_callback(lambda do |param|
      "Callback got: #{param}"
    end)

    assert_equal "Callback got: Hello", cb.fire_callback("Hello")
  end

  def hello_world(param)
    "Method got: #{param}"
  end

  def test_callbacks_sample_method
    cb = CallbackHolder.new
    cb.register_callback method(:hello_world)

    assert_equal "Method got: Hello", cb.fire_callback("Hello")
  end
end
