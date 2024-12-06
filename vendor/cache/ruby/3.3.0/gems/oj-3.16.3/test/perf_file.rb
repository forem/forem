#!/usr/bin/env ruby -wW1
# frozen_string_literal: true

$LOAD_PATH << '.'
$LOAD_PATH << '../lib'
$LOAD_PATH << '../ext'

if __FILE__ == $PROGRAM_NAME && (i = ARGV.index('-I'))
  _, path = ARGV.slice!(i, 2)
  $LOAD_PATH << path
end

require 'optparse'
require 'oj'
require 'perf'

@indent = 0
@iter = 1
@size = 1

opts = OptionParser.new

opts.on('-r', 'read')                                       { true }
opts.on('-c', '--count [Int]', Integer, 'iterations')       { |v| @iter = v }
opts.on('-i', '--indent [Int]', Integer, 'indent')          { |v| @indent = v }
opts.on('-s', '--size [Int]', Integer, 'size in Mbytes')    { |s| @size = s }

opts.on('-h', '--help', 'Show this display')                { puts opts; Process.exit!(0) }
opts.parse(ARGV)

@obj = {
  'a' => 'Alpha', # string
  'b' => true,    # boolean
  'c' => 12_345,   # number
  'd' => [ true, [false, [-123_456_789, nil], 3.9676, ['Something else.', false], nil]], # mix it up array
  'e' => { 'zero' => nil, 'one' => 1, 'two' => 2, 'three' => [3], 'four' => [0, 1, 2, 3, 4] }, # hash
  'f' => nil,     # nil
  'g' => 12_345_678_901_234_567_890_123_456_789, # _bignum
  'h' => { 'a' => { 'b' => { 'c' => { 'd' => {'e' => { 'f' => { 'g' => nil }}}}}}}, # deep hash, not that deep
  'i' => [[[[[[[nil]]]]]]]  # deep array, again, not that deep
}

json = Oj.dump(@obj, :indent => @indent)
cnt = ((@size * 1024 * 1024) + json.size) / json.size
cnt = 1 if 0 == @size

filename = 'tmp.json'
File.open(filename, 'w') { |f|
  cnt.times do
    Oj.to_stream(f, @obj, :indent => @indent)
  end
}

Oj.default_options = { :mode => :strict, :indent => @indent }

puts '-' * 80
puts "Read from #{cnt * json.size / (1024 * 1024)} Mb file Performance"
perf = Perf.new()
perf.add('Oj.load_file', '') { Oj.load_file(filename) }
perf.add('Oj.load(string)', '') { Oj.load(File.read(filename)) }
perf.add('Oj.load(file)', '') { File.open(filename, 'r') { |f| Oj.load(f) } }
perf.run(@iter)
