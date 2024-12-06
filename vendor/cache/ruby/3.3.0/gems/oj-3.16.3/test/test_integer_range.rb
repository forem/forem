#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__
@oj_dir = File.dirname(File.expand_path(__dir__))
%w(lib ext).each do |dir|
  $LOAD_PATH << File.join(@oj_dir, dir)
end

require 'minitest'
require 'minitest/autorun'
require 'oj'

class IntegerRangeTest < Minitest::Test
  def setup
    @default_options = Oj.default_options
    # in null mode other options other than the number formats are not used.
    Oj.default_options = { :mode => :null, bigdecimal_as_decimal: true }
  end

  def teardown
    Oj.default_options = @default_options
  end

  def test_range
    test = {s: 0, s2: -1, s3: 1, u: -2, u2: 2, u3: 9_007_199_254_740_993}
    exp = '{"s":0,"s2":-1,"s3":1,"u":"-2","u2":"2","u3":"9007199254740993"}'
    assert_equal(exp, Oj.dump(test, integer_range: (-1..1)))
  end

  def test_bignum
    test = {u: -10_000_000_000_000_000_000, u2: 10_000_000_000_000_000_000}
    exp = '{"u":"-10000000000000000000","u2":"10000000000000000000"}'
    assert_equal(exp, Oj.dump(test, integer_range: (-1..1)))
  end

  def test_valid_modes
    test = {safe: 0, unsafe: 9_007_199_254_740_993}
    exp  = '{"safe":0,"unsafe":"9007199254740993"}'

    [:strict, :null, :compat, :rails, :custom].each do |mode|
      assert_equal(exp, Oj.dump(test, mode: mode, integer_range: (-1..1)), "Invalid mode #{mode}")
    end

    exp = '{":safe":0,":unsafe":"9007199254740993"}'
    [:object].each do |mode|
      assert_equal(exp, Oj.dump(test, mode: mode, integer_range: (-1..1)), "Invalid mode #{mode}")
    end
  end

  def test_modes_without_opt
    test = {safe: 0, unsafe: 10_000_000_000_000_000_000}
    exp = '{"safe":0,"unsafe":10000000000000000000}'

    [:strict, :null, :compat, :rails, :custom].each do |mode|
      assert_equal(exp, Oj.dump(test, mode: mode), "Invalid mode #{mode}")
    end

    exp = '{":safe":0,":unsafe":10000000000000000000}'
    [:object].each do |mode|
      assert_equal(exp, Oj.dump(test, mode: mode), "Invalid mode #{mode}")
    end
  end

  def test_accept_nil_and_false
    test = {safe: 0, unsafe: 10_000_000_000_000_000_000}
    exp = '{"safe":0,"unsafe":10000000000000000000}'

    assert_equal(exp, Oj.dump(test, integer_range: nil))
    assert_equal(exp, Oj.dump(test, integer_range: false))
  end
end
