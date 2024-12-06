#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "highline/import"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

# tounge_twister
ask("... try saying that three times fast") do |q|
  q.gather = 3
  q.verify_match = true
  q.responses[:mismatch] = "Nope, those don't match. Try again."
end

puts "Ok, you did it."

pass = ask("<%= key %>:  ") do |q|
  q.echo = "*"
  q.verify_match = true
  q.gather = { "Enter a password" => "",
               "Please type it again for verification" => "" }
end

puts "Your password is now #{pass}!"
