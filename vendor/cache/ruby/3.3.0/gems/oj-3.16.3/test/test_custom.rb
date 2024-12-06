#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__
@oj_dir = File.dirname(File.expand_path(__dir__))
%w(lib ext).each do |dir|
  $LOAD_PATH << File.join(@oj_dir, dir)
end

require 'minitest'
require 'minitest/autorun'
require 'stringio'
require 'date'
require 'bigdecimal'
require 'oj'

class CustomJuice < Minitest::Test

  module TestModule
  end

  class Jeez
    attr_accessor :x, :y, :_z

    def initialize(x, y)
      @x = x
      @y = y
      @_z = x.to_s
    end

    def ==(o)
      self.class == o.class && @x == o.x && @y = o.y
    end

    def to_json(*_args)
      %|{"xx":#{@x},"yy":#{y}}|
    end

    def raw_json(_depth, _indent)
      %|{"xxx":#{@x},"yyy":#{y}}|
    end

    def as_json(*_args)
      {'a' => @x, :b => @y }
    end

    def to_hash
      {'b' => @x, 'n' => @y }
    end
  end

  class AsJson
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def ==(o)
      self.class == o.class && @x == o.x && @y = o.y
    end

    def as_json(*_args)
      {'a' => @x, :b => @y }
    end
  end

  class AsRails
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def ==(o)
      self.class == o.class && @x == o.x && @y = o.y
    end

    def as_json(*_args)
      a = @x
      a = a.as_json if a.respond_to?('as_json')
      b = @y
      b = b.as_json if b.respond_to?('as_json')
      {'a' => a, :b => b }
    end
  end

  def setup
    @default_options = Oj.default_options
    Oj.default_options = { :mode => :custom }
  end

  def teardown
    Oj.default_options = @default_options
  end

  def test_nil
    dump_and_load(nil, false)
  end

  def test_true
    dump_and_load(true, false)
  end

  def test_false
    dump_and_load(false, false)
  end

  def test_fixnum
    dump_and_load(0, false)
    dump_and_load(12_345, false)
    dump_and_load(-54_321, false)
    dump_and_load(1, false)
  end

  def test_float
    dump_and_load(0.0, false)
    dump_and_load(12_345.6789, false)
    dump_and_load(70.35, false)
    dump_and_load(-54_321.012, false)
    dump_and_load(1.7775, false)
    dump_and_load(2.5024, false)
    dump_and_load(2.48e16, false)
    dump_and_load(2.48e100 * 1.0e10, false)
    dump_and_load(-2.48e100 * 1.0e10, false)
  end

  def test_float_parse
    f = Oj.load('12.123456789012345678', mode: :custom, bigdecimal_load: :float)
    assert_equal(Float, f.class)
  end

  def test_float_parse_fast
    f = Oj.load('12.123456789012345678', mode: :custom, bigdecimal_load: :fast)
    assert_equal(Float, f.class)
    assert(12.12345678901234 <= f && f < 12.12345678901236)
  end

  def test_nan_dump
    assert_equal('null', Oj.dump(0/0.0, :nan => :null))
    assert_equal('3.3e14159265358979323846', Oj.dump(0/0.0, :nan => :huge))
    assert_equal('NaN', Oj.dump(0/0.0, :nan => :word))
    begin
      Oj.dump(0/0.0, :nan => :raise)
    rescue Exception
      assert(true)
      return
    end
    assert(false, '*** expected an exception')
  end

  def test_infinity_dump
    assert_equal('null', Oj.dump(1/0.0, :nan => :null))
    assert_equal('3.0e14159265358979323846', Oj.dump(1/0.0, :nan => :huge))
    assert_equal('Infinity', Oj.dump(1/0.0, :nan => :word))
    begin
      Oj.dump(1/0.0, :nan => :raise)
    rescue Exception
      assert(true)
      return
    end
    assert(false, '*** expected an exception')
  end

  def test_neg_infinity_dump
    assert_equal('null', Oj.dump(-1/0.0, :nan => :null))
    assert_equal('-3.0e14159265358979323846', Oj.dump(-1/0.0, :nan => :huge))
    assert_equal('-Infinity', Oj.dump(-1/0.0, :nan => :word))
    begin
      Oj.dump(-1/0.0, :nan => :raise)
    rescue Exception
      assert(true)
      return
    end
    assert(false, '*** expected an exception')
  end

  def test_string
    dump_and_load('', false)
    dump_and_load('abc', false)
    dump_and_load("abc\ndef", false)
    dump_and_load("a\u0041", false)
  end

  def test_string_ascii
    json = Oj.dump('ぴーたー', :escape_mode => :ascii)
    assert_equal(%{"\\u3074\\u30fc\\u305f\\u30fc"}, json)
    dump_and_load('ぴーたー', false, :escape_mode => :ascii)
  end

  def test_string_json
    json = Oj.dump('ぴーたー', :escape_mode => :json)
    assert_equal(%{"ぴーたー"}, json)
    dump_and_load('ぴーたー', false, :escape_mode => :json)
  end

  def test_array
    dump_and_load([], false)
    dump_and_load([true, false], false)
    dump_and_load(['a', 1, nil], false)
    dump_and_load([[nil]], false)
    dump_and_load([[nil], 58], false)
  end

  def test_array_deep
    dump_and_load([1, [2, [3, [4, [5, [6, [7, [8, [9, [10, [11, [12, [13, [14, [15, [16, [17, [18, [19, [20]]]]]]]]]]]]]]]]]]]], false)
  end

  def test_deep_nest
    skip 'TruffleRuby causes SEGV' if RUBY_ENGINE == 'truffleruby'

    begin
      n = 10_000
      Oj.strict_load(('[' * n) + (']' * n))
    rescue Exception => e
      refute(e.message)
    end
  end

  def test_hash
    dump_and_load({}, false)
    dump_and_load({ 'true' => true, 'false' => false}, false)
    dump_and_load({ 'true' => true, 'array' => [], 'hash' => { }}, false)
  end

  def test_hash_deep
    dump_and_load({'1' => {
                      '2' => {
                        '3' => {
                          '4' => {
                            '5' => {
                              '6' => {
                                '7' => {
                                  '8' => {
                                    '9' => {
                                      '10' => {
                                        '11' => {
                                          '12' => {
                                            '13' => {
                                              '14' => {
                                                '15' => {
                                                  '16' => {
                                                    '17' => {
                                                      '18' => {
                                                        '19' => {
                                                          '20' => {}}}}}}}}}}}}}}}}}}}}}, false)
  end

  def test_hash_escaped_key
    json = %{{"a\nb":true,"c\td":false}}
    obj = Oj.load(json)
    assert_equal({"a\nb" => true, "c\td" => false}, obj)
  end

  def test_hash_non_string_key
    assert_equal(%|{"1":true}|, Oj.dump({ 1 => true }, :indent => 0))
  end

  def test_bignum_object
    dump_and_load(7 ** 55, false)
  end

  def test_bigdecimal
    assert_equal('0.314159265358979323846e1', Oj.dump(BigDecimal('3.14159265358979323846'), bigdecimal_as_decimal: true).downcase())
    assert_equal('"0.314159265358979323846e1"', Oj.dump(BigDecimal('3.14159265358979323846'), bigdecimal_as_decimal: false).downcase())
    dump_and_load(BigDecimal('3.14159265358979323846'), false, :bigdecimal_load => true)
  end

  def test_object
    obj = Jeez.new(true, 58)
    json = Oj.dump(obj, create_id: '^o', use_to_json: false, use_as_json: false, use_to_hash: false)
    assert_equal(%|{"x":true,"y":58,"_z":"true"}|, json)
    json = Oj.dump(obj, create_id: '^o', use_to_json: false, use_as_json: false, use_to_hash: false, ignore_under: true)
    assert_equal(%|{"x":true,"y":58}|, json)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_object_to_json
    obj = Jeez.new(true, 58)
    json = Oj.dump(obj, :use_to_json => true, :use_as_json => false, :use_to_hash => false)
    assert_equal(%|{"xx":true,"yy":58}|, json)
  end

  def test_object_as_json
    obj = Jeez.new(true, 58)
    json = Oj.dump(obj, :use_to_json => false, :use_as_json => true, :use_to_hash => false)
    assert_equal(%|{"a":true,"b":58}|, json)
  end

  def test_object_to_hash
    obj = Jeez.new(true, 58)
    json = Oj.dump(obj, :use_to_json => false, :use_as_json => false, :use_to_hash => true)
    assert_equal(%|{"b":true,"n":58}|, json)
  end

  def test_object_raw_json
    obj = Jeez.new(true, 58)
    json = Oj.dump(obj, :use_to_json => true, :use_as_json => false, :use_raw_json => true, :use_to_hash => false)
    assert_equal(%|{"xxx":true,"yyy":58}|, json)
  end

  def test_raw_json_stringwriter
    obj = Oj::StringWriter.new(:indent => 0)
    obj.push_array()
    obj.pop()
    json = Oj.dump(obj, :use_raw_json => true)
    assert_equal(%|[]|, json)
  end

  def test_as_raw_json_stringwriter
    obj = Oj::StringWriter.new(:indent => 0)
    obj.push_array()
    obj.push_value(3)
    obj.pop()
    j = AsJson.new(1, obj)

    json = Oj.dump(j, use_raw_json: true, use_as_json: true, indent: 2)
    assert_equal(%|{
  "a":1,
  "b":[3]
}
|, json)

    json = Oj.dump(j, use_raw_json: false, use_as_json: true, indent: 2)
    assert_equal(%|{
  "a":1,
  "b":{}
}
|, json)
  end

  def test_rails_as_raw_json_stringwriter
    obj = Oj::StringWriter.new(:indent => 0)
    obj.push_array()
    obj.push_value(3)
    obj.pop()
    j = AsRails.new(1, obj)
    json = Oj.dump(j, mode: :rails, use_raw_json: true, indent: 2)
    assert_equal(%|{
  "a":1,
  "b":{}
}
|, json)

    Oj::Rails.optimize
    json = Oj.dump(j, mode: :rails, use_raw_json: true, indent: 2)
    Oj::Rails.deoptimize
    assert_equal(%|{
  "a":1,
  "b":[3]
}
|, json)
  end

  def test_symbol
    json = Oj.dump(:abc)
    assert_equal('"abc"', json)
  end

  def test_class
    assert_equal(%|"CustomJuice"|, Oj.dump(CustomJuice))
  end

  def test_module
    assert_equal(%|"CustomJuice::TestModule"|, Oj.dump(TestModule))
  end

  def test_symbol_keys
    json = %|{
  "x":true,
  "y":58,
  "z": [1,2,3]
}
|
    obj = Oj.load(json, :symbol_keys => true)
    assert_equal({ :x => true, :y => 58, :z => [1, 2, 3]}, obj)
  end

  def test_double
    json = %{{ "x": 1}{ "y": 2}}
    results = []
    Oj.load(json, :mode => :strict) { |x| results << x }

    assert_equal([{ 'x' => 1 }, { 'y' => 2 }], results)
  end

  def test_circular_hash
    h = { 'a' => 7 }
    h['b'] = h
    json = Oj.dump(h, :indent => 2, :circular => true)
    assert_equal(%|{
  "a":7,
  "b":null
}
|, json)
  end

  def test_omit_nil
    json = Oj.dump({'x' => {'a' => 1, 'b' => nil }, 'y' => nil}, :omit_nil => true)
    assert_equal(%|{"x":{"a":1}}|, json)
  end

  def test_omit_null_byte
    json = Oj.dump({ "fo\x00o" => "b\x00ar" }, :omit_null_byte => true)
    assert_equal(%|{"foo":"bar"}|, json)
  end

  def test_complex
    obj = Complex(2, 9)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_rational
    obj = Rational(2, 9)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_range
    obj = 3..8
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_date
    obj = Date.new(2017, 1, 5)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_date_unix
    obj = Date.new(2017, 1, 5)
    json = Oj.dump(obj, :indent => 2, time_format: :unix)
    assert_equal('1483574400.000000000', json)
  end

  def test_date_unix_zone
    obj = Date.new(2017, 1, 5)
    json = Oj.dump(obj, :indent => 2, time_format: :unix_zone)
    assert_equal('1483574400.000000000', json)
  end

  def test_date_ruby
    obj = Date.new(2017, 1, 5)
    json = Oj.dump(obj, :indent => 2, time_format: :ruby)
    assert_equal('"2017-01-05"', json)
  end

  def test_date_xmlschema
    obj = Date.new(2017, 1, 5)
    json = Oj.dump(obj, :indent => 2, time_format: :xmlschema)
    assert_equal('"2017-01-05"', json)
  end

  def test_datetime
    obj = DateTime.new(2017, 1, 5, 10, 20, 30)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_datetime_unix
    obj = DateTime.new(2017, 1, 5, 10, 20, 30, '-0500')
    json = Oj.dump(obj, :indent => 2, time_format: :unix)
    assert_equal('1483629630.000000000', json)
  end

  def test_datetime_unix_zone
    obj = DateTime.new(2017, 1, 5, 10, 20, 30, '-0500')
    json = Oj.dump(obj, :indent => 2, time_format: :unix_zone)
    assert_equal('1483629630.000000000e-18000', json)
  end

  def test_datetime_ruby
    obj = DateTime.new(2017, 1, 5, 10, 20, 30, '-0500')
    json = Oj.dump(obj, :indent => 2, time_format: :ruby)
    assert_equal('"2017-01-05T10:20:30-05:00"', json)
  end

  def test_datetime_xmlschema
    obj = DateTime.new(2017, 1, 5, 10, 20, 30, '-0500')
    json = Oj.dump(obj, :indent => 2, time_format: :xmlschema)
    assert_equal('"2017-01-05T10:20:30-05:00"', json)
  end

  def test_regexp
    # this notation must be used to get an == match later
    obj = /(?ix-m:^yes$)/
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_openstruct
    obj = OpenStruct.new(:a => 1, 'b' => 2)
    dump_and_load(obj, false, :create_id => '^o', :create_additions => true)
  end

  def test_time
    skip 'TruffleRuby fails this spec' if RUBY_ENGINE == 'truffleruby'

    obj = Time.now()
    # These two forms should be able to recreate the time precisely,
    # so we check they can load a dumped version and recreate the
    # original object correctly.
    dump_and_load(obj, false, :time_format => :unix, :create_id => '^o', :create_additions => true)
    dump_and_load(obj, false, :time_format => :unix_zone, :create_id => '^o', :create_additions => true)
    # These two forms will lose precision while dumping as they don't
    # preserve full precision. We check that a dumped version is equal
    # to that version loaded and dumped a second time, but don't check
    # that the loaded Ruby object is still the same as the original.
    dump_load_dump(obj, false, :time_format => :xmlschema, :create_id => '^o', :create_additions => true)
    dump_load_dump(obj, false, :time_format => :xmlschema, :create_id => '^o', :create_additions => true, second_precision: 3)
    dump_load_dump(obj, false, :time_format => :ruby, :create_id => '^o', :create_additions => true)
  end

  def dump_and_load(obj, trace=false, options={})
    options = options.merge(:indent => 2, :mode => :custom)
    json = Oj.dump(obj, options)
    puts json if trace

    loaded = Oj.load(json, options)
    if obj.nil?
      assert_nil(loaded)
    else
      assert_equal(obj, loaded)
    end
    loaded
  end

  def dump_and_load_inspect(obj, trace=false, options={})
    options = options.merge(:indent => 2, :mode => :custom)
    json = Oj.dump(obj, options)
    puts json if trace

    loaded = Oj.load(json, options)
    if obj.nil?
      assert_nil(loaded)
    else
      assert_equal(obj.inspect, loaded.inspect)
    end
    loaded
  end

  def dump_load_dump(obj, trace=false, options={})
    options = options.merge(:indent => 2, :mode => :custom)
    json = Oj.dump(obj, options)
    puts json if trace

    loaded = Oj.load(json, options)
    if obj.nil?
      assert_nil(loaded)
    else
      json2 = Oj.dump(loaded, options)
      assert_equal(json, json2)
    end
    loaded
  end

end
