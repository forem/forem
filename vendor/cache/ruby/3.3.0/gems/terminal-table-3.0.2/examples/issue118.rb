#!/usr/bin/env ruby

require_relative '../lib/terminal-table'

puts Terminal::Table.new(headings: ['a', 'b', 'c', 'd'], style: { border: :unicode })

puts

tbl = Terminal::Table.new do |t|
  t.style = { border: :unicode }
  t.add_separator
  t.add_separator
  t.add_row ['x','y','z']
  t.add_separator
  t.add_separator
end
puts tbl

puts

puts Terminal::Table.new(headings: [['a', 'b', 'c', 'd'], ['cat','dog','frog','mouse']], style: { border: :unicode })

puts

puts Terminal::Table.new(headings: ['a', 'b', 'c', 'd'])

puts

tbl = Terminal::Table.new do |t|
  t.add_separator
  t.add_separator
  t.add_row ['x','y','z']
  t.add_separator
  t.add_separator
end
puts tbl
