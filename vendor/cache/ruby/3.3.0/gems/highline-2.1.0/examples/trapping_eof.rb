#!/usr/bin/env ruby
# encoding: utf-8

# trapping_eof.rb
#
#  Created by James Edward Gray II on 2006-02-20.
#  Copyright 2006 Gray Productions. All rights reserved.

require "rubygems"
require "highline/import"

loop do
  begin
    name = ask("What's your name?")
    break if name == "exit"
    puts "Hello, #{name}!"
  rescue EOFError # HighLine throws this if @input.eof?
    break
  end
end

puts "Goodbye, dear friend."
exit
