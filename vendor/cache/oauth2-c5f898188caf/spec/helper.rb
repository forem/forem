require 'oauth2'
require 'simplecov'
require 'coveralls'
require 'rspec'
require 'rspec/stubbed_env'
require 'silent_stream'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

SimpleCov.start do
  add_filter '/spec'
  minimum_coverage(95)
end

require 'addressable/uri'

Faraday.default_adapter = :test

DEBUG = ENV['DEBUG'] == 'true'
if DEBUG && RUBY_VERSION >= '2.6'
  require 'byebug'
end

# This is dangerous - HERE BE DRAGONS.
# It allows us to refer to classes without the namespace, but at what cost?!?
# TODO: Refactor to use explicit references everywhere
include OAuth2

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include SilentStream
end

VERBS = [:get, :post, :put, :delete].freeze
