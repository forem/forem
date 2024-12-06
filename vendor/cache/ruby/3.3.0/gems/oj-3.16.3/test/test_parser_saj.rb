#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__

require 'helper'

$json = %|{
  "array": [
    {
      "num"   : 3,
      "string": "message",
      "hash"  : {
        "h2"  : {
          "a" : [ 1, 2, 3 ]
        }
      }
    }
  ],
  "boolean" : true
}|

class AllSaj < Oj::Saj
  attr_accessor :calls

  def initialize
    @calls = []

    super
  end

  def hash_start(key)
    @calls << [:hash_start, key]
  end

  def hash_end(key)
    @calls << [:hash_end, key]
  end

  def array_start(key)
    @calls << [:array_start, key]
  end

  def array_end(key)
    @calls << [:array_end, key]
  end

  def add_value(value, key)
    @calls << [:add_value, value, key]
  end

  def error(message, line, column)
    @calls << [:error, message, line, column]
  end

end # AllSaj

class LocSaj
  attr_accessor :calls

  def initialize
    @calls = []
  end

  def hash_start(key, line, column)
    @calls << [:hash_start, key, line, column]
  end

  def hash_end(key, line, column)
    @calls << [:hash_end, key, line, column]
  end

  def array_start(key, line, column)
    @calls << [:array_start, key, line, column]
  end

  def array_end(key, line, column)
    @calls << [:array_end, key, line, column]
  end

  def add_value(value, key, line, column)
    @calls << [:add_value, value, key, line, column]
  end

end # LocSaj

class SajTest < Minitest::Test

  def test_nil
    handler = AllSaj.new()
    json = %{null}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, nil, nil]], handler.calls)
  end

  def test_true
    handler = AllSaj.new()
    json = %{true}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, true, nil]], handler.calls)
  end

  def test_false
    handler = AllSaj.new()
    json = %{false}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, false, nil]], handler.calls)
  end

  def test_string
    handler = AllSaj.new()
    json = %{"a string"}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, 'a string', nil]], handler.calls)
  end

  def test_fixnum
    handler = AllSaj.new()
    json = %{12345}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, 12_345, nil]], handler.calls)
  end

  def test_float
    handler = AllSaj.new()
    json = %{12345.6789}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:add_value, 12_345.6789, nil]], handler.calls)
  end

  def test_float_exp
    handler = AllSaj.new()
    json = %{12345.6789e7}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal(1, handler.calls.size)
    assert_equal(:add_value, handler.calls[0][0])
    assert_equal((12_345.6789e7 * 10_000).to_i, (handler.calls[0][1] * 10_000).to_i)
  end

  def test_bignum
    handler = AllSaj.new()
    json = %{-11.899999999999999}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal(1, handler.calls.size)
    assert_equal(:add_value, handler.calls[0][0])
    assert_equal(-118_999, (handler.calls[0][1] * 10_000).to_i)
  end

  def test_bignum_loc
    handler = LocSaj.new()
    json = <<~JSON
      {
        "width": 192.33800000000002,
        "xaxis": {
          "anchor": "y"
        }
      }
    JSON

    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal(6, handler.calls.size)
    assert_equal(1_923_380, (handler.calls[1][1] * 10_000).to_i)
    handler.calls[1][1] = 1_923_380
    assert_equal([[:hash_start, nil, 1, 1],
                  [:add_value, 1_923_380, 'width', 2, 30],
                  [:hash_start, 'xaxis', 3, 12],
                  [:add_value, 'y', 'anchor', 4, 17],
                  [:hash_end, 'xaxis', 5, 3],
                  [:hash_end, nil, 6, 1]],
                 handler.calls)
  end

  def test_array_empty
    handler = AllSaj.new()
    json = %{[]}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:array_start, nil],
                  [:array_end, nil]], handler.calls)
  end

  def test_array
    handler = AllSaj.new()
    json = %{[true,false]}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:array_start, nil],
                  [:add_value, true, nil],
                  [:add_value, false, nil],
                  [:array_end, nil]], handler.calls)
  end

  def test_hash_empty
    handler = AllSaj.new()
    json = %{{}}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:hash_start, nil],
                  [:hash_end, nil]], handler.calls)
  end

  def test_hash
    handler = AllSaj.new()
    json = %{{"one":true,"two":false}}
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([[:hash_start, nil],
                  [:add_value, true, 'one'],
                  [:add_value, false, 'two'],
                  [:hash_end, nil]], handler.calls)
  end

  def test_full
    handler = AllSaj.new()
    Oj.saj_parse(handler, $json)
    assert_equal([[:hash_start, nil],
                  [:array_start, 'array'],
                  [:hash_start, nil],
                  [:add_value, 3, 'num'],
                  [:add_value, 'message', 'string'],
                  [:hash_start, 'hash'],
                  [:hash_start, 'h2'],
                  [:array_start, 'a'],
                  [:add_value, 1, nil],
                  [:add_value, 2, nil],
                  [:add_value, 3, nil],
                  [:array_end, 'a'],
                  [:hash_end, 'h2'],
                  [:hash_end, 'hash'],
                  [:hash_end, nil],
                  [:array_end, 'array'],
                  [:add_value, true, 'boolean'],
                  [:hash_end, nil]], handler.calls)
  end

  def test_multiple
    handler = AllSaj.new()
    json = %|[true][false]|
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.parse(json)
    assert_equal([
                   [:array_start, nil],
                   [:add_value, true, nil],
                   [:array_end, nil],
                   [:array_start, nil],
                   [:add_value, false, nil],
                   [:array_end, nil],
                 ], handler.calls)
  end

  def test_io
    handler = AllSaj.new()
    json = %| [true,false]  |
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.load(StringIO.new(json))
    assert_equal([
                   [:array_start, nil],
                   [:add_value, true, nil],
                   [:add_value, false, nil],
                   [:array_end, nil],
                 ], handler.calls)
  end

  def test_file
    handler = AllSaj.new()
    p = Oj::Parser.new(:saj)
    p.handler = handler
    p.file('saj_test.json')
    assert_equal([
                   [:array_start, nil],
                   [:add_value, true, nil],
                   [:add_value, false, nil],
                   [:array_end, nil],
                 ], handler.calls)
  end

  def test_default
    handler = AllSaj.new()
    json = %|[true]|
    Oj::Parser.saj.handler = handler
    Oj::Parser.saj.parse(json)
    assert_equal([
                   [:array_start, nil],
                   [:add_value, true, nil],
                   [:array_end, nil],
                 ], handler.calls)
  end

  def test_loc
    handler = LocSaj.new()
    Oj::Parser.saj.handler = handler
    Oj::Parser.saj.parse($json)
    assert_equal([[:hash_start, nil, 1, 1],
                  [:array_start, 'array', 2, 12],
                  [:hash_start, nil, 3, 5],
                  [:add_value, 3, 'num', 4, 18],
                  [:add_value, 'message', 'string', 5, 25],
                  [:hash_start, 'hash', 6, 17],
                  [:hash_start, 'h2', 7, 17],
                  [:array_start, 'a', 8, 17],
                  [:add_value, 1, nil, 8, 20],
                  [:add_value, 2, nil, 8, 23],
                  [:add_value, 3, nil, 8, 26],
                  [:array_end, 'a', 8, 27],
                  [:hash_end, 'h2', 9, 9],
                  [:hash_end, 'hash', 10, 7],
                  [:hash_end, nil, 11, 5],
                  [:array_end, 'array', 12, 3],
                  [:add_value, true, 'boolean', 13, 18],
                  [:hash_end, nil, 14, 1]], handler.calls)
  end

end
