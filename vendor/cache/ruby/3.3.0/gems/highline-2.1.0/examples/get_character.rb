#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "highline/import"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

choices = "ynaq"
answer = ask("Your choice [#{choices}]? ") do |q|
  q.echo = false
  q.character = true
  q.validate  = /\A[#{choices}]\Z/
end
say("Your choice: #{answer}")
