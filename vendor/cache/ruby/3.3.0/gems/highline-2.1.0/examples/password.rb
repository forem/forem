#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "highline/import"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

pass = ask("Enter your password:  ") { |q| q.echo = false }
puts "Your password is #{pass}!"
