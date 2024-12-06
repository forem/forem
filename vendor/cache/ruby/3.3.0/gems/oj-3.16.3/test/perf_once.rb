#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'oj'

filename = 'tmp.json'
File.open(filename, 'w') { |f|
  cnt = 0
  f.puts('{')
  ('a'..'z').each { |a|
    ('a'..'z').each { |b|
      ('a'..'z').each { |c|
        ('a'..'z').each { |d|
          f.puts(%|"#{a}#{b}#{c}#{d}":#{cnt},|)
          cnt += 1
        }
      }
    }
  }
  f.puts('"_last":0}')
}

def mem
  `ps -o rss= -p #{$PROCESS_ID}`.to_i
end

Oj.default_options = { mode: :strict, cache_keys: false, cache_str: -1 }
start = Time.now
Oj.load_file('tmp.json')
dur = Time.now - start
GC.start
puts "no cache duration: #{dur} @ #{mem}"

Oj.default_options = { cache_keys: true }
start = Time.now
Oj.load_file('tmp.json')
dur = Time.now - start
GC.start
puts "initial cache duration: #{dur} @ #{mem}"

start = Time.now
Oj.load_file('tmp.json')
dur = Time.now - start
GC.start
puts "second cache duration: #{dur} @ #{mem}"

10.times { GC.start }
start = Time.now
Oj.load_file('tmp.json')
dur = Time.now - start
GC.start
puts "after several GCs cache duration: #{dur} @ #{mem}"

# TBD check memory use
