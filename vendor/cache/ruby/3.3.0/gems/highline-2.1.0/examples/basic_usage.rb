#!/usr/bin/env ruby
# encoding: utf-8

# basic_usage.rb
#
#  Created by James Edward Gray II on 2005-04-28.
#  Copyright 2005 Gray Productions. All rights reserved.

require "rubygems"
require "highline/import"
require "yaml"

puts "Using: #{HighLine.default_instance.terminal.class}"
puts

contacts = []

# Just define a parse class method and use the class
# as a parser for HighLine#ask
#
class NameClass
  def self.parse(string)
    raise ArgumentError, "Invalid name format." unless
      string =~ /^\s*(\w+),\s*(\w+)\s*$/

    new(Regexp.last_match(2), Regexp.last_match(1))
  end

  def initialize(first, last)
    @first = first
    @last = last
  end

  attr_reader :first, :last
end

loop do
  entry = {}

  # basic output
  say("Enter a contact:")

  # basic input
  entry[:name] = ask("Name?  (last, first)  ", NameClass) do |q|
    q.validate = /\A\w+, ?\w+\Z/
  end
  entry[:company]     = ask("Company?  ") { |q| q.default = "none" }
  entry[:address]     = ask("Address?  ")
  entry[:city]        = ask("City?  ")
  entry[:state]       = ask("State?  ") do |q|
    q.case     = :up
    q.validate = /\A[A-Z]{2}\Z/
  end
  entry[:zip] = ask("Zip?  ") do |q|
    q.validate = /\A\d{5}(?:-?\d{4})?\Z/
  end
  entry[:phone] = ask("Phone?  ",
                      lambda { |p|
                        p.delete("^0-9").
                                     sub(/\A(\d{3})/, '(\1) ').
                                     sub(/(\d{4})\Z/, '-\1')
                      }) do |q|
    q.validate              = ->(p) { p.delete("^0-9").length == 10 }
    q.responses[:not_valid] = "Enter a phone numer with area code."
  end
  entry[:age]         = ask("Age?  ", Integer) { |q| q.in = 0..105 }
  entry[:birthday]    = ask("Birthday?  ", Date)
  entry[:interests]   = ask("Interests?  (comma separated list)  ",
                            ->(str) { str.split(/,\s*/) })
  entry[:description] = ask("Enter a description for this contact.") do |q|
    q.whitespace = :strip_and_collapse
  end

  contacts << entry
  # shortcut for yes and no questions
  break unless agree("Enter another contact?  ", true)
end

if agree("Save these contacts?  ", true)
  file_name = ask("Enter a file name:  ") do |q|
    q.validate = /\A\w+\Z/
    q.confirm  = true
  end
  File.open("#{file_name}.yaml", "w") { |file| YAML.dump(contacts, file) }
end
