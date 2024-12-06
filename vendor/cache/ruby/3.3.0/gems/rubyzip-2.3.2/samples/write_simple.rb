#!/usr/bin/env ruby

$LOAD_PATH << '../lib'

require 'zip'

::Zip::OutputStream.open('simple.zip') do |zos|
  zos.put_next_entry 'entry.txt'
  zos.puts 'Hello world'
end
