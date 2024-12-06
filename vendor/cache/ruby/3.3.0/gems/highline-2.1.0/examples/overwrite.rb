#!/usr/bin/env ruby
# encoding: utf-8

# overwrite.rb
#
#  Created by Jeremy Hinegardner on 2007-01-24
#  Copyright 2007 Jeremy Hinegardner.  All rights reserved

require "rubygems"
require "highline/import"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

prompt = "here is your password:"
ask(
  "#{prompt} <%= color('mypassword', RED, BOLD) %> (Press Any Key to blank) "
) do |q|
  q.overwrite = true
  q.echo      = false  # overwrite works best when echo is false.
  q.character = true   # if this is set to :getc then overwrite does not work
end
say("<%= color('Look! blanked out!', GREEN) %>")
