#!/usr/bin/env ruby
require_relative "../lib/terminal-table"

#
# An example of how to manually add separators with non-default
# border_type to enable a footer row.
#
table = Terminal::Table.new do |t|
  # set the style
  t.style = { border: :unicode_thick_edge }
  
  # header row
  t.headings = ['fruit', 'count']

  # some row data
  t.add_row ['apples', 7]
  t.add_row ['bananas', 19]
  t.add_separator border_type: :strong
  # footer row
  t.add_row ['total', 26] 
end

puts table.render
