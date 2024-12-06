#!/usr/bin/ruby

# demo the "revalidate" feature in libvips 8.15

require "fileutils"
require "vips"

if ARGV.length != 2
  puts "usage: ./revalidate.rb IMAGE-FILE-1 IMAGE-FILE-2"
  exit 1
end

if File.exist?("fred")
  puts "file 'fred' exists, delete it first"
  exit 1
end

puts "copying #{ARGV[0]} to fred ..."
FileUtils.cp(ARGV[0], "fred")

image1 = Vips::Image.new_from_file("fred")
puts "fred.width = #{image1.width}"

puts "copying #{ARGV[1]} to fred ..."
FileUtils.cp(ARGV[1], "fred")

puts "plain image open ..."
image2 = Vips::Image.new_from_file("fred")
puts "fred.width = #{image2.width}"

puts "opening with revalidate ..."
image2 = Vips::Image.new_from_file("fred", revalidate: true)
puts "fred.width = #{image2.width}"

puts "opening again, should get cached entry ..."
image2 = Vips::Image.new_from_file("fred")
puts "fred.width = #{image2.width}"

File.delete("fred")
