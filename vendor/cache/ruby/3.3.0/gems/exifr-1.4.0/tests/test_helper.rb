#!/usr/bin/env ruby
#
# Copyright (c) 2006-2020 - R.W. van 't Veer

require 'stringio'
require 'pp'

TestCase = begin
             tc = begin
                    gem 'minitest' rescue nil
                    require 'minitest/autorun'
                    case
                    when defined?(Minitest::Test) ; Minitest::Test
                    when defined?(Minitest::Unit::TestCase) ; Minitest::Unit::TestCase
                    end
                  rescue LoadError
                    # nop
                  end
             unless tc
               require "test/unit"
               tc = Test::Unit::TestCase
             end
             tc
           end

$:.unshift("#{File.dirname(__FILE__)}/../lib")
require 'exifr/jpeg'
require 'exifr/tiff'
include EXIFR

EXIFR.logger = Logger.new(StringIO.new)

def all_test_jpegs
  Dir[f('*.jpg')]
end

def all_test_exifs
  Dir[f('*.exif')]
end

def all_test_tiffs
  Dir[f('*.tif')] + all_test_exifs
end

def f(fname)
  "#{File.dirname(__FILE__)}/data/#{fname}"
end

def assert_literally_equal(expected, actual, *args)
  assert_equal expected.to_s_literally, actual.to_s_literally, *args
end

class Hash
  def to_s_literally
    keys.map{|k| k.to_s}.sort.map{|k| "#{k.inspect} => #{self[k].inspect}" }.join(', ')
  end
end

class Object
  def to_s_literally
    to_s
  end
end
