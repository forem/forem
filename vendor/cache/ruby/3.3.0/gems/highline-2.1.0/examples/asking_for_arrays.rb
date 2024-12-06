#!/usr/bin/env ruby
# encoding: utf-8

# asking_for_arrays.rb
#
#  Created by James Edward Gray II on 2005-07-05.
#  Copyright 2005 Gray Productions. All rights reserved.

require "rubygems"
require "highline/import"
require "pp"

puts "Using: #{HighLine.default_instance.class}"
puts

grades = ask("Enter test scores (or a blank line to quit):",
             ->(ans) { ans =~ /^-?\d+$/ ? Integer(ans) : ans }) do |q|
  q.gather = ""
end

say("Grades:")
pp grades
