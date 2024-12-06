#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__

require 'helper'

class UsualTest < Minitest::Test

  def test_nil
    p = Oj::Parser.new(:usual)
    doc = p.parse('nil')
    assert_nil(doc)
  end

  def test_primitive
    p = Oj::Parser.new(:usual)
    [
      ['true', true],
      ['false', false],
      ['123', 123],
      ['1.25', 1.25],
      ['"abc"', 'abc'],
    ].each { |x|
      doc = p.parse(x[0])
      assert_equal(x[1], doc)
    }
  end

  def test_big
    p = Oj::Parser.new(:usual)
    doc = p.parse('12345678901234567890123456789')
    assert_equal(BigDecimal, doc.class)
    doc = p.parse('1234567890.1234567890123456789')
    assert_equal(BigDecimal, doc.class)
  end

  def test_array
    p = Oj::Parser.new(:usual)
    [
      ['[]', []],
      ['[false]', [false]],
      ['[true,false]', [true, false]],
      ['[[]]', [[]]],
      ['[true,[],false]', [true, [], false]],
      ['[true,[true],false]', [true, [true], false]],
    ].each { |x|
      doc = p.parse(x[0])
      assert_equal(x[1], doc)
    }
  end

  def test_hash
    p = Oj::Parser.new(:usual)
    [
      ['{}', {}],
      ['{"a": null}', {'a' => nil}],
      ['{"t": true, "f": false, "s": "abc"}', {'t' => true, 'f' => false, 's' => 'abc'}],
      ['{"a": {}}', {'a' => {}}],
      ['{"a": {"b": 2}}', {'a' => {'b' => 2}}],
      ['{"a": [true]}', {'a' => [true]}],
    ].each { |x|
      doc = p.parse(x[0])
      assert_equal(x[1], doc)
    }
  end

  def test_symbol_keys
    p = Oj::Parser.new(:usual)
    refute(p.symbol_keys)
    p.symbol_keys = true
    doc = p.parse('{"a": true, "b": false}')
    assert_equal({a: true, b: false}, doc)
  end

  def test_strings
    p = Oj::Parser.new(:usual)
    doc = p.parse('{"ぴ": "", "ぴ ": "x", "c": "ぴーたー", "d": " ぴーたー "}')
    assert_equal({'ぴ' => '', 'ぴ ' => 'x', 'c' => 'ぴーたー', 'd' => ' ぴーたー '}, doc)
  end

  def test_capacity
    p = Oj::Parser.new(:usual, capacity: 1000)
    assert_equal(4096, p.capacity)
    p.capacity = 5000
    assert_equal(5000, p.capacity)
  end

  def test_decimal
    p = Oj::Parser.new(:usual)
    assert_equal(:auto, p.decimal)
    doc = p.parse('1.234567890123456789')
    assert_equal(BigDecimal, doc.class)
    assert_equal('0.1234567890123456789e1', doc.to_s)
    doc = p.parse('1.25')
    assert_equal(Float, doc.class)

    p.decimal = :float
    assert_equal(:float, p.decimal)
    doc = p.parse('1.234567890123456789')
    assert_equal(Float, doc.class)

    p.decimal = :bigdecimal
    assert_equal(:bigdecimal, p.decimal)
    doc = p.parse('1.234567890123456789')
    assert_equal(BigDecimal, doc.class)
    doc = p.parse('1.25')
    assert_equal(BigDecimal, doc.class)
    assert_equal('0.125e1', doc.to_s)

    p.decimal = :ruby
    assert_equal(:ruby, p.decimal)
    doc = p.parse('1.234567890123456789')
    assert_equal(Float, doc.class)
  end

  def test_omit_null
    p = Oj::Parser.new(:usual)
    p.omit_null = true
    doc = p.parse('{"a":true,"b":null}')
    assert_equal({'a'=>true}, doc)

    p.omit_null = false
    doc = p.parse('{"a":true,"b":null}')
    assert_equal({'a'=>true, 'b'=>nil}, doc)
  end

  class MyArray < Array
  end

  def test_array_class
    p = Oj::Parser.new(:usual)
    p.array_class = MyArray
    assert_equal(MyArray, p.array_class)
    doc = p.parse('[true]')
    assert_equal(MyArray, doc.class)
  end

  class MyHash < Hash
  end

  def test_hash_class
    p = Oj::Parser.new(:usual)
    p.hash_class = MyHash
    assert_equal(MyHash, p.hash_class)
    doc = p.parse('{"a":true}')
    assert_equal(MyHash, doc.class)
  end

  def test_empty
    p = Oj::Parser.new(:usual)
    p.raise_on_empty = false
    doc = p.parse('  ')
    assert_nil(doc)

    p.raise_on_empty = true
    assert_raises(Oj::ParseError) { p.parse('  ') }
  end

  class MyClass
    attr_accessor :a
    attr_accessor :b

    def to_s
      "#{self.class}{a: #{@a} b: #{b}}"
    end
  end

  class MyClass2 < MyClass
    def self.json_create(arg)
      obj = new
      obj.a = arg['a']
      obj.b = arg['b']
      obj
    end
  end

  def test_create_id
    p = Oj::Parser.new(:usual)
    p.create_id = '^'
    doc = p.parse('{"a":true}')
    assert_equal(Hash, doc.class)
    doc = p.parse('{"a":true,"^":"UsualTest::MyClass","b":false}')
    assert_equal('UsualTest::MyClass{a: true b: false}', doc.to_s)

    doc = p.parse('{"a":true,"^":"UsualTest::MyClass2","b":false}')
    assert_equal('UsualTest::MyClass2{a: true b: false}', doc.to_s)

    p.hash_class = MyHash
    assert_equal(MyHash, p.hash_class)
    doc = p.parse('{"a":true}')
    assert_equal(MyHash, doc.class)

    doc = p.parse('{"a":true,"^":"UsualTest::MyClass","b":false}')
    assert_equal('UsualTest::MyClass{a: true b: false}', doc.to_s)
  end

  def test_missing_class
    p = Oj::Parser.new(:usual, create_id: '^')
    json = '{"a":true,"^":"Auto","b":false}'
    doc = p.parse(json)
    assert_equal(Hash, doc.class)

    p.missing_class = :auto
    doc = p.parse(json)
    # Auto should be defined after parsing
    assert_equal(Auto, doc.class)
  end

  def test_class_cache
    p = Oj::Parser.new(:usual)
    p.create_id = '^'
    p.class_cache = true
    p.missing_class = :auto
    json = '{"a":true,"^":"Auto2","b":false}'
    doc = p.parse(json)
    assert_equal(Auto2, doc.class)

    doc = p.parse(json)
    assert_equal(Auto2, doc.class)
  end

  def test_default_parser
    doc = Oj::Parser.usual.parse('{"a":true,"b":null}')
    assert_equal({'a'=>true, 'b'=>nil}, doc)
  end
end
