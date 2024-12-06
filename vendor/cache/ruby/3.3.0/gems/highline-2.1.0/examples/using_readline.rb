#!/usr/bin/env ruby
# encoding: utf-8

# using_readline.rb
#
#  Created by James Edward Gray II on 2005-07-06.
#  Copyright 2005 Gray Productions. All rights reserved.

require "rubygems"
require "highline/import"

loop do
  cmd = ask("Enter command:  ", %w[save sample load reset quit]) do |q|
    q.readline = true
  end
  say("Executing \"#{cmd}\"...")
  break if cmd == "quit"
end
