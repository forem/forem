#!/usr/bin/env ruby

# Methods to suppress left/right borders using border_left & border_right

require_relative "../lib/terminal-table"
table = Terminal::Table.new do |t|
  t.headings = ['id', 'name']
  t.rows = [[1, 'One'], [2, 'Two'], [3, 'Three']]
  t.style = { :border_left => false, :border_top => false, :border_bottom => false }
end

puts table
puts

# no right
table.style = {:border_right => false }
puts table
puts

# no right
table.style = {:border_left => true }
puts table
puts

table.style.border = Terminal::Table::UnicodeBorder.new
puts table


table.style = {:border_right => false, :border_left => true }
puts table

table.style = {:border_right => true, :border_left => false }
puts table

