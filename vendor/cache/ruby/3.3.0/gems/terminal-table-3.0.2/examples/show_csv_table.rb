#!/usr/bin/env ruby

require "csv"
$LOAD_PATH << "#{__dir__}/../lib"
require "terminal-table"

#
# Usage:
#   ./show_csv_table.rb data.csv
#   cat data.csv | ./show_csv_table.rb
#   cat data.csv | ./show_csv_table.rb -
#
#
# Reads a CSV from $stdin if no argument given, or argument is '-'
# otherwise interprets first cmdline argument as the CSV filename
#
use_stdin = ARGV[0].nil? || (ARGV[0] == '-')
io_object = use_stdin ? $stdin : File.open(ARGV[0], 'r')
csv = CSV.new(io_object)

#
# Convert to an array for use w/ terminal-table
# The assumption is that this is a pretty small spreadsheet.
#
csv_array = csv.to_a

user_table = Terminal::Table.new do |v|
  v.style = { :border => :unicode_round } # >= v3.0.0
  v.title = "Some Title"
  v.headings = csv_array[0]
  v.rows = csv_array[1..-1]
end

puts user_table
