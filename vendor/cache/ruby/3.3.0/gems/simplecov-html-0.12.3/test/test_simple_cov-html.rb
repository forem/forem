# frozen_string_literal: true

require "helper"

class TestSimpleCovHtml < Minitest::Test
  def test_defined
    assert defined?(SimpleCov::Formatter::HTMLFormatter)
    assert defined?(SimpleCov::Formatter::HTMLFormatter::VERSION)
  end
end
