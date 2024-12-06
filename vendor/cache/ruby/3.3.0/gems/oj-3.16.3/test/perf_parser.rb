#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'optparse'
require 'perf'
require 'oj'
require 'json'

$verbose = false
$iter = 50_000
$with_bignum = false
$size = 1
$cache_keys = true
$symbol_keys = false

opts = OptionParser.new
opts.on('-v', 'verbose')                                  { $verbose = true }
opts.on('-c', '--count [Int]', Integer, 'iterations')     { |i| $iter = i }
opts.on('-s', '--size [Int]', Integer, 'size (~Kbytes)')  { |i| $size = i }
opts.on('-b', 'with bignum')                              { $with_bignum = true }
opts.on('-k', 'no cache')                                 { $cache_keys = false }
opts.on('-sym', 'symbol keys')                            { $symbol_keys = true }
opts.on('-h', '--help', 'Show this display')              { puts opts; Process.exit!(0) }
opts.parse(ARGV)

$obj = {
  'a' => 'Alpha', # string
  'b' => true,    # boolean
  'c' => 12_345,   # number
  'd' => [ true, [false, [-123_456_789, nil], 3.9676, ['Something else.', false, 1, nil], nil]], # mix it up array
  'e' => { 'zero' => nil, 'one' => 1, 'two' => 2, 'three' => [3], 'four' => [0, 1, 2, 3, 4] }, # hash
  'f' => nil,     # nil
  'h' => { 'a' => { 'b' => { 'c' => { 'd' => {'e' => { 'f' => { 'g' => nil }}}}}}}, # deep hash, not that deep
  'i' => [[[[[[[nil]]]]]]]  # deep array, again, not that deep
}
$obj['g'] = 12_345_678_901_234_567_890_123_456_789 if $with_bignum

if 0 < $size
  o = $obj
  $obj = []
  (4 * $size).times do
    $obj << o
  end
end

$json = Oj.dump($obj)
$failed = {} # key is same as String used in tests later
Oj.default_options = {create_id: '^', create_additions: true, class_cache: true}
Oj.default_options = if $cache_keys
                       {cache_keys: true, cache_str: 6, symbol_keys: $symbol_keys}
                     else
                       {cache_keys: false, cache_str: -1, symbol_keys: $symbol_keys}
                     end
JSON.parser = JSON::Ext::Parser

class AllSaj

  def hash_start(key)
  end

  def hash_end(key)
  end

  def array_start(key)
  end

  def array_end(key)
  end

  def add_value(value, key)
  end
end # AllSaj

no_handler = Object.new()
all_handler = AllSaj.new()

if $verbose
  puts "json:\n#{$json}\n"
end

### Validate ######################
p_val = Oj::Parser.new(:validate)

puts '-' * 80
puts 'Validate Performance'
perf = Perf.new()
perf.add('Oj::Parser.validate', 'none') { p_val.parse($json) }
perf.add('Oj::Saj.none', 'none') { Oj.saj_parse(no_handler, $json) }
perf.run($iter)

### SAJ ######################
p_all = Oj::Parser.new(:saj)
p_all.handler = all_handler
p_all.cache_keys = $cache_keys
p_all.cache_strings = 6

puts '-' * 80
puts 'Parse Callback Performance'
perf = Perf.new()
perf.add('Oj::Parser.saj', 'all') { p_all.parse($json) }
perf.add('Oj::Saj.all', 'all') { Oj.saj_parse(all_handler, $json) }
perf.run($iter)

### Usual ######################
p_usual = Oj::Parser.new(:usual)
p_usual.cache_keys = $cache_keys
p_usual.cache_strings = ($cache_keys ? 6 : 0)
p_usual.symbol_keys = $symbol_keys

puts '-' * 80
puts 'Parse Usual Performance'
perf = Perf.new()
perf.add('Oj::Parser.usual', '') { p_usual.parse($json) }
perf.add('Oj::strict_load', '') { Oj.strict_load($json) }
perf.add('JSON::Ext', 'parse') { JSON.parse($json) }
perf.run($iter)

### Usual Objects ######################

# Original Oj follows the JSON gem for creating objects which uses the class
# json_create(arg) method. Oj::Parser in usual mode supprts the same but also
# handles populating the object variables directly which is faster.

class Stuff
  attr_accessor :alpha, :bravo, :charlie, :delta, :echo, :foxtrot, :golf, :hotel, :india, :juliet

  def self.json_create(arg)
    obj = new
    obj.alpha = arg['alpha']
    obj.bravo = arg['bravo']
    obj.charlie = arg['charlie']
    obj.delta = arg['delta']
    obj.echo = arg['echo']
    obj.foxtrot = arg['foxtrot']
    obj.golf = arg['golf']
    obj.hotel = arg['hotel']
    obj.india = arg['india']
    obj.juliet = arg['juliet']
    obj
  end
end

$obj_json = %|{
  "alpha": [0, 1,2,3,4,5,6,7,8,9],
  "bravo": true,
  "charlie": 123,
  "delta": "some string",
  "echo": null,
  "^": "Stuff",
  "foxtrot": false,
  "golf": "gulp",
  "hotel": {"x": true, "y": false},
  "india": [null, true, 123],
  "juliet": "junk"
}|

p_usual = Oj::Parser.new(:usual)
p_usual.cache_keys = $cache_keys
p_usual.cache_strings = ($cache_keys ? 6 : 0)
p_usual.symbol_keys = $symbol_keys
p_usual.create_id = '^'
p_usual.class_cache = true
p_usual.ignore_json_create = true

JSON.create_id = '^'

puts '-' * 80
puts 'Parse Usual Object Performance'
perf = Perf.new()
perf.add('Oj::Parser.usual', '') { p_usual.parse($obj_json) }
perf.add('Oj::compat_load', '') { Oj.compat_load($obj_json) }
perf.add('JSON::Ext', 'parse') { JSON.parse($obj_json) }

perf.run($iter)

unless $failed.empty?
  puts 'The following packages were not included for the reason listed'
  $failed.each { |tag, msg| puts "***** #{tag}: #{msg}" }
end
