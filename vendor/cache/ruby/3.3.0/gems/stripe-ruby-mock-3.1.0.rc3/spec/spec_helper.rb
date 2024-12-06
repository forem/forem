require 'set'

gem 'rspec', '~> 3.1'
require 'rspec'
require 'stripe'
require 'stripe_mock'
require 'stripe_mock/server'
require 'dotenv'

Dotenv.load('.env')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |c|
  tags = c.filter_manager.inclusions.rules

  if tags.include?(:live) || tags.include?(:oauth)
    puts "Running **live** tests against Stripe..."
    StripeMock.set_default_test_helper_strategy(:live)

    if tags.include?(:oauth)
      oauth_token = ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN']
      if oauth_token.nil? || oauth_token == ''
        raise "Please set your STRIPE_TEST_OAUTH_ACCESS_TOKEN environment variable."
      end
      c.filter_run_excluding :mock_server => true, :live => true
    else
      c.filter_run_excluding :mock_server => true, :oauth => true
    end

    if ENV['IS_TRAVIS']
      puts "Travis ruby version: #{RUBY_VERSION}"
      api_key = case RUBY_VERSION
      when '2.4.6'  then ENV['STRIPE_TEST_SECRET_KEY_A']
      when '2.5.5' then ENV['STRIPE_TEST_SECRET_KEY_B']
      when '2.6.3'  then ENV['STRIPE_TEST_SECRET_KEY_C']
      when '2.7.0'  then ENV['STRIPE_TEST_SECRET_KEY_D']
      end
    else
      api_key = ENV['STRIPE_TEST_SECRET_KEY']
      if api_key.nil? || api_key == ''
        raise "Please set your STRIPE_TEST_SECRET_KEY environment variable."
      end
    end

    c.before(:each) do
      allow(StripeMock).to receive(:start).and_return(nil)
      allow(StripeMock).to receive(:stop).and_return(nil)
      Stripe.api_key = api_key
    end
    c.after(:each) { sleep 0.01 }
  else
    c.filter_run_excluding :oauth => true
    Stripe.api_key ||= ''
  end

  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
end
