# frozen_string_literal: true

require 'spec_helper'
require 'active_support'
require 'active_support/notifications'

describe 'Instrumentation' do
  let(:backend) { Faraday::Adapter::Test::Stubs.new }

  let(:client) do
    Faraday.new do |stack|
      stack.use Faraday::HttpCache, instrumenter: ActiveSupport::Notifications
      stack.adapter :test, backend
    end
  end

  let(:events) { [] }
  let(:subscriber) { lambda { |*args| events << ActiveSupport::Notifications::Event.new(*args) } }

  around do |example|
    ActiveSupport::Notifications.subscribed(subscriber, 'http_cache.faraday') do
      example.run
    end
  end

  describe 'the :cache_status payload entry' do
    it 'is :miss if there is no cache entry for the URL' do
      backend.get('/hello') do
        [200, { 'Cache-Control' => 'public, max-age=999' }, '']
      end

      client.get('/hello')
      expect(events.last.payload.fetch(:cache_status)).to eq(:miss)
    end

    it 'is :fresh if the cache entry has not expired' do
      backend.get('/hello') do
        [200, { 'Cache-Control' => 'public, max-age=999' }, '']
      end

      client.get('/hello') # miss
      client.get('/hello') # fresh!
      expect(events.last.payload.fetch(:cache_status)).to eq(:fresh)
    end

    it 'is :valid if the cache entry can be validated against the upstream' do
      backend.get('/hello') do
        headers = {
          'Cache-Control' => 'public, must-revalidate, max-age=0',
          'Etag' => '123ABCD'
        }

        [200, headers, '']
      end

      client.get('/hello') # miss

      backend.get('/hello') { [304, {}, ''] }

      client.get('/hello') # valid!
      expect(events.last.payload.fetch(:cache_status)).to eq(:valid)
    end

    it 'is :invalid if the cache entry could not be validated against the upstream' do
      backend.get('/hello') do
        headers = {
          'Cache-Control' => 'public, must-revalidate, max-age=0',
          'Etag' => '123ABCD'
        }

        [200, headers, '']
      end

      client.get('/hello') # miss

      backend.get('/hello') { [200, {}, ''] }

      client.get('/hello') # invalid!
      expect(events.last.payload.fetch(:cache_status)).to eq(:invalid)
    end
  end
end
