#!/usr/bin/env ruby -wW2
# frozen_string_literal: true

if $PROGRAM_NAME == __FILE__
  $LOAD_PATH << '.'
  $LOAD_PATH << '..'
  $LOAD_PATH << '../lib'
  $LOAD_PATH << '../ext'
end

require 'sample/file'
require 'sample/dir'

def files(dir)
  d = Sample::Dir.new(dir)
  Dir.new(dir).each do |fn|
    next if fn.start_with?('.')

    filename = File.join(dir, fn)
    # filename = '.' == dir ? fn : File.join(dir, fn)
    d << if File.directory?(filename)
           files(filename)
         else
           Sample::File.new(filename)
         end
  end
  # pp d
  d
end
