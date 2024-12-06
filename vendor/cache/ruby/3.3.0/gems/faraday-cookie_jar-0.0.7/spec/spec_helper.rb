require 'rspec'
require 'faraday-cookie_jar'

require 'sham_rack'
require_relative 'support/fake_app'

ShamRack.at('faraday.example.com').rackup do
  run FakeApp
end
