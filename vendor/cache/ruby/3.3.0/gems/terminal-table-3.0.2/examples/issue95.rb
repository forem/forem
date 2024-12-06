#!/usr/bin/env ruby
require 'colorize'
require_relative '../lib/terminal-table.rb'

original_sample_data = [
["Sep 2016", 33, [-38, -53.52], 46, [-25, -35.21]],
["Oct 2016", 35, [2, 6.06], 50, [4, 8.69]]
]

table = Terminal::Table.new headings: ["Month".cyan,"Monthly IT".cyan,"IT Difference OPM".cyan,
"Monthly OOT".cyan,"OOT Difference OPM".cyan], rows: original_sample_data

table.style = { padding_left: 2, padding_right: 2, border_x: "-".blue, border_y: "|".blue, border_i: "+".blue }

puts table

puts ""
puts "^ good table"
puts "v wonky table"
puts ""

split_column_sample_data = [
["Sep 2016", 33, -38, -53.52, 46, -25, -35.21],
["Oct 2016", 35, 2, 6.06, 50, 4, 8.69]
]

table = Terminal::Table.new headings: ["Month".cyan,"Monthly IT".cyan,
{value: "IT Difference OPM".cyan, colspan: 2}, "Monthly OOT".cyan,
{value: "OOT Difference OPM".cyan, colspan: 2}], rows: split_column_sample_data

table.style = { padding_left: 2, padding_right: 2, border_x: "-".blue, border_y: "|".blue, border_i: "+".blue }

puts table


table = Terminal::Table.new headings: ["Month","Monthly IT",
{value: "IT Difference OPM", colspan: 2}, "Monthly OOT",
{value: "OOT Difference OPM", colspan: 2}], rows: split_column_sample_data

table.style = { padding_left: 2, padding_right: 2, border_x: "-".blue, border_y: "|".cyan, border_i: "+" }

puts table
