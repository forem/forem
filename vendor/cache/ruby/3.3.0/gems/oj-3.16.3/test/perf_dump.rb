#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'optparse'
require 'oj'

@verbose = false
@indent = 2
@iter = 100_000
@size = 2

opts = OptionParser.new
opts.on('-v', 'verbose')                                    { @verbose = true }
opts.on('-c', '--count [Int]', Integer, 'iterations')       { |i| @iter = i }
opts.on('-i', '--indent [Int]', Integer, 'indentation')     { |i| @indent = i }
opts.on('-s', '--size [Int]', Integer, 'size (~Kbytes)')    { |i| @size = i }
opts.on('-h', '--help', 'Show this display')                { puts opts; Process.exit!(0) }
opts.parse(ARGV)

@obj = {
  'a' => 'Alpha', # string
  'b' => true,    # boolean
  'c' => 12_345,   # number
  'd' => [ true, [false, [-123_456_789, nil], 3.9676, ['Something else.', false], nil]], # mix it up array
  'e' => { 'zero' => nil, 'one' => 1, 'two' => 2, 'three' => [3], 'four' => [0, 1, 2, 3, 4] }, # hash
  'f' => nil,     # nil
  'h' => { 'a' => { 'b' => { 'c' => { 'd' => { 'e' => { 'f' => { 'g' => nil }}}}}}}, # deep hash, not that deep
  'i' => [[[[[[[nil]]]]]]]  # deep array, again, not that deep
}

Oj.default_options = { :indent => @indent, :mode => :strict }

if 0 < @size
  o = @obj
  @obj = []
  (4 * @size).times do
    @obj << o
  end
end

@json = Oj.dump(@obj)
GC.start
start = Time.now
@iter.times { Oj.dump(@obj) }
duration = Time.now - start
puts "Dumped #{@json.length} byte JSON #{@iter} times in %0.3f seconds or %0.3f iteration/sec." % [duration, @iter / duration]
