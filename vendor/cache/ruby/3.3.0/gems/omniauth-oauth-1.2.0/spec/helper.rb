$LOAD_PATH.unshift File.expand_path("..", __FILE__)
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "simplecov"
SimpleCov.start do
  minimum_coverage(89.79)
end
require "rspec"
require "rack/test"
require "webmock/rspec"
require "omniauth"
require "omniauth-oauth"

OmniAuth.config.request_validation_phase = nil

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
end

OmniAuth.config.logger = Logger.new("/dev/null")
