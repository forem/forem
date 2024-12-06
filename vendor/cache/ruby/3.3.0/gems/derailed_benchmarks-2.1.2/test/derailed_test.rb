# frozen_string_literal: true

require 'test_helper'

class DerailedBenchmarksTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, DerailedBenchmarks
  end

  test "gem_is_bundled?" do
    assert DerailedBenchmarks.gem_is_bundled?("rack")
    refute DerailedBenchmarks.gem_is_bundled?("wicked")
  end

  test "readme contains correct output" do
    readme_path = File.join(__dir__, "..", "README.md")
    lines = File.foreach(readme_path)
    lineno = 1
    expected = lines.lazy.drop_while { |line|
      lineno += 1
      line != "$ bundle exec derailed exec --help\n"
    }.drop(1).take_while { |line| line != "```\n" }.force.join.split("\n").sort
    actual = `bundle exec derailed exec --help`.split("\n").sort
    assert_equal(
      expected,
      actual,
      "Please update README.md:#{lineno}"
    )
  end
end
