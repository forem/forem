# frozen_string_literal: true

require 'simplecov'

SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'front_matter_parser'
require 'pry-byebug'
Dir["#{File.expand_path('support', __dir__)}/*.rb"].each do |file|
  require file
end
