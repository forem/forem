#!/usr/bin/env ruby
require_relative "../lib/terminal-table"
puts Terminal::Table.new(headings: ['heading A', 'heading B'], rows: [['a', 'b'], ['a', 'b']], style: {border: Terminal::Table::MarkdownBorder.new})

