$LOAD_PATH.unshift File.expand_path("..", __FILE__)
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

if RUBY_VERSION >= "1.9"
  require "simplecov"
  require "coveralls"

  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

  SimpleCov.start do
    minimum_coverage(78.48)
  end
end

require "rspec"
require "rack/test"
require "webmock/rspec"
require "omniauth"
require "omniauth-oauth2"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
  config.include Rack::Test::Methods
  config.include WebMock::API
end
