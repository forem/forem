require 'bundler/setup'
require 'minitest/autorun'
require 'mocha/setup'
require 'omniauth/strategies/facebook'

OmniAuth.config.test_mode = true

module BlockTestHelper
  def test(name, &blk)
    method_name = "test_#{name.gsub(/\s+/, '_')}"
    raise "Method already defined: #{method_name}" if instance_methods.include?(method_name.to_sym)
    define_method method_name, &blk
  end
end

module CustomAssertions
  def assert_has_key(key, hash, msg = nil)
    msg = message(msg) { "Expected #{hash.inspect} to have key #{key.inspect}" }
    assert hash.has_key?(key), msg
  end

  def refute_has_key(key, hash, msg = nil)
    msg = message(msg) { "Expected #{hash.inspect} not to have key #{key.inspect}" }
    refute hash.has_key?(key), msg
  end
end

class TestCase < Minitest::Test
  extend BlockTestHelper
  include CustomAssertions
end

class StrategyTestCase < TestCase
  def setup
    @request = stub('Request')
    @request.stubs(:params).returns({})
    @request.stubs(:cookies).returns({})
    @request.stubs(:env).returns({})
    @request.stubs(:scheme).returns({})
    @request.stubs(:ssl?).returns(false)

    @client_id = '123'
    @client_secret = '53cr3tz'
    @options = {}

    @facebook_api_version = OmniAuth::Strategies::Facebook::DEFAULT_FACEBOOK_API_VERSION
  end

  def strategy
    @strategy ||= begin
      args = [@client_id, @client_secret, @options].compact
      OmniAuth::Strategies::Facebook.new(nil, *args).tap do |strategy|
        strategy.stubs(:request).returns(@request)
      end
    end
  end
end

Dir[File.expand_path('../support/**/*', __FILE__)].each(&method(:require))
