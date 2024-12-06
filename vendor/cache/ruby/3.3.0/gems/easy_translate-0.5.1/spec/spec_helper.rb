# Start SimpleCov
begin
  require 'ostruct'
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts 'for coverage please install SimpleCov'
end

require 'ostruct'

# Require the actual project
$: << File.expand_path('../lib', __FILE__)
require 'easy_translate'
