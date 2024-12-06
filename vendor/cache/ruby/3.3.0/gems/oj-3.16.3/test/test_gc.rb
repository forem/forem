#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << __dir__

require 'helper'

class GCTest < Minitest::Test
  class Goo
    attr_accessor :x, :child

    def initialize(x, child)
      @x = x
      @child = child
    end

    def to_hash
      { 'json_class' => self.class.to_s, 'x' => x, 'child' => child }
    end

    def self.json_create(h)
      GC.start
      new(h['x'], h['child'])
    end
  end # Goo

  def setup
    @default_options = Oj.default_options
    GC.stress = true
  end

  def teardown
    Oj.default_options = @default_options
    GC.stress = false
  end

  # if no crash then the GC marking is working
  def test_parse_compat_gc
    g = Goo.new(0, nil)
    100.times { |i| g = Goo.new(i, g) }
    json = Oj.dump(g, :mode => :compat)
    Oj.compat_load(json)
  end

  def test_parse_object_gc
    g = Goo.new(0, nil)
    100.times { |i| g = Goo.new(i, g) }
    json = Oj.dump(g, :mode => :object)
    Oj.object_load(json)
  end

  def test_parse_gc
    json = '{"a":"Alpha","b":true,"c":12345,"d":[true,[false,[-123456789,null],3.9676,["Something else.",false],null]],"e":{"zero":null,"one":1,"two":2,"three":[3],"four":[0,1,2,3,4]},"f":null,"h":{"a":{"b":{"c":{"d":{"e":{"f":{"g":null}}}}}}},"i":[[[[[[[null]]]]]]]}'

    50.times do
      data = Oj.load(json)
      assert_equal(json, Oj.dump(data))
    end
  end
end
