# frozen_string_literal: true

require 'uri'
require 'socket'

require 'faraday-http-cache'

if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('1.0')
  require 'faraday_middleware'
elsif ENV['FARADAY_ADAPTER'] == 'em_http'
  require 'faraday/em_http'
end

require 'active_support'
require 'active_support/cache'

require 'support/test_app'
require 'support/test_server'

server = TestServer.new

ENV['FARADAY_SERVER'] = server.endpoint
ENV['FARADAY_ADAPTER'] ||= 'net_http'

server.start

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'

  config.after(:suite) do
    server.stop
  end
end
