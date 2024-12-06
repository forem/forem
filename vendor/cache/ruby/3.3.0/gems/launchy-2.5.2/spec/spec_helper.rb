if RUBY_VERSION >= '1.9.2' then
  require 'simplecov'
  puts "Using coverage!"
  SimpleCov.start if ENV['COVERAGE']
end

gem 'minitest'
require 'launchy'
require 'stringio'
require 'minitest/autorun'
require 'minitest/pride'
