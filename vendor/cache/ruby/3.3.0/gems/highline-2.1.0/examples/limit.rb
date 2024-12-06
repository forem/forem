#!/usr/bin/env ruby -w
# encoding: utf-8

# limit.rb
#
#  Created by James Edward Gray II on 2008-11-12.
#  Copyright 2008 Gray Productions. All rights reserved.

require "rubygems"
require "highline/import"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

text = ask("Enter text (max 10 chars): ") { |q| q.limit = 10 }
puts "You entered: #{text}!"
