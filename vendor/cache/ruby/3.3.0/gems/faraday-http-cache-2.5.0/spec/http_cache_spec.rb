# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache do
  let(:logger) { double('a Logger object', debug: nil, warn: nil) }
  let(:options) { { logger: logger } }

  let(:client) do
    Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
      stack.use Faraday::HttpCache, options
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      stack.adapter adapter.to_sym
    end
  end

  before do
    client.get('clear')
  end

  it 'does not cache POST requests' do
    client.post('post').body
    expect(client.post('post').body).to eq('2')
  end

  it 'logs that a POST request is unacceptable' do
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [POST /post] unacceptable, delete') }
    client.post('post').body
  end

  it 'does not cache responses with , status code' do
    client.get('broken')
    expect(client.get('broken').body).to eq('2')
  end

  it 'adds a trace of the actions performed to the env' do
    response = client.post('post')
    expect(response.env[:http_cache_trace]).to eq(%i[unacceptable delete])
  end

  describe 'cache invalidation' do
    it 'expires POST requests' do
      client.get('counter')
      client.post('counter')
      expect(client.get('counter').body).to eq('2')
    end

    it 'logs that a POST request was deleted from the cache' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [POST /counter] unacceptable, delete') }
      client.post('counter')
    end

    it 'does not expires POST requests that failed' do
      client.get('get')
      client.post('get')
      expect(client.get('get').body).to eq('1')
    end

    it 'expires PUT requests' do
      client.get('counter')
      client.put('counter')
      expect(client.get('counter').body).to eq('2')
    end

    it 'logs that a PUT request was deleted from the cache' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [PUT /counter] unacceptable, delete') }
      client.put('counter')
    end

    it 'expires DELETE requests' do
      client.get('counter')
      client.delete('counter')
      expect(client.get('counter').body).to eq('2')
    end

    it 'logs that a DELETE request was deleted from the cache' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [DELETE /counter] unacceptable, delete') }
      client.delete('counter')
    end

    it 'expires PATCH requests' do
      client.get('counter')
      client.patch('counter')
      expect(client.get('counter').body).to eq('2')
    end

    it 'logs that a PATCH request was deleted from the cache' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [PATCH /counter] unacceptable, delete') }
      client.patch('counter')
    end

    it 'logs that a response with a bad status code is uncacheable' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /broken] miss, uncacheable') }
      client.get('broken')
    end

    it 'expires entries for the "Location" header' do
      client.get('get')
      client.post('delete-with-location')
      expect(client.get('get').body).to eq('2')
    end

    it 'expires entries for the "Content-Location" header' do
      client.get('get')
      client.post('delete-with-content-location')
      expect(client.get('get').body).to eq('2')
    end
  end

  describe 'when acting as a shared cache' do
    let(:options) { { logger: logger, shared_cache: true } }

    it 'does not cache requests with a private cache control' do
      client.get('private')
      expect(client.get('private').body).to eq('2')
    end

    it 'logs that a private response is uncacheable' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /private] miss, uncacheable') }
      client.get('private')
    end
  end

  describe 'when acting as a private cache' do
    let(:options) { { logger: logger, shared_cache: false } }

    it 'does cache requests with a private cache control' do
      client.get('private')
      expect(client.get('private').body).to eq('1')
    end

    it 'logs that a private response is stored' do
      expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /private] miss, store') }
      client.get('private')
    end
  end

  it 'does not cache responses with a explicit no-store directive' do
    client.get('dontstore')
    expect(client.get('dontstore').body).to eq('2')
  end

  it 'logs that a response with a no-store directive is uncacheable' do
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /dontstore] miss, uncacheable') }
    client.get('dontstore')
  end

  it 'does not caches multiple responses when the headers differ' do
    client.get('get', nil, 'HTTP_ACCEPT' => 'text/html')
    expect(client.get('get', nil, 'HTTP_ACCEPT' => 'text/html').body).to eq('1')
    expect(client.get('get', nil, 'HTTP_ACCEPT' => 'application/json').body).to eq('1')
  end

  it 'caches multiples responses based on the "Vary" header' do
    client.get('vary', nil, 'User-Agent' => 'Agent/1.0')
    expect(client.get('vary', nil, 'User-Agent' => 'Agent/1.0').body).to eq('1')
    expect(client.get('vary', nil, 'User-Agent' => 'Agent/2.0').body).to eq('2')
    expect(client.get('vary', nil, 'User-Agent' => 'Agent/3.0').body).to eq('3')
  end

  it 'never caches responses with the wildcard "Vary" header' do
    client.get('vary-wildcard')
    expect(client.get('vary-wildcard').body).to eq('2')
  end

  it 'caches requests with the "Expires" header' do
    client.get('expires')
    expect(client.get('expires').body).to eq('1')
  end

  it 'logs that a request with the "Expires" is fresh and stored' do
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /expires] miss, store') }
    client.get('expires')
  end

  it 'caches GET responses' do
    client.get('get')
    expect(client.get('get').body).to eq('1')
  end

  context 'when the request has a "no-cache" directive' do
    it 'revalidates the cache' do
      expect(client.get('etag').body).to eq('1')
      expect(client.get('etag', nil, 'Cache-Control' => 'no-cache').body).to eq('1')

      expect(client.get('get', nil).body).to eq('2')
      expect(client.get('etag', nil, 'Cache-Control' => 'no-cache').body).to eq('3')
    end

    it 'caches the response' do
      client.get('get', nil, 'Cache-Control' => 'no-cache')
      expect(client.get('get', nil).body).to eq('1')
    end
  end

  context 'when the response has a "no-cache" directive' do
    it 'always revalidate the cached response' do
      client.get('no_cache')
      expect(client.get('no_cache').body).to eq('2')
      expect(client.get('no_cache').body).to eq('3')
    end
  end

  it 'logs that a GET response is stored' do
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /get] miss, store') }
    client.get('get')
  end

  it 'differs requests with different query strings in the log' do
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /get] miss, store') }
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /get?q=what] miss, store') }
    client.get('get')
    client.get('get', q: 'what')
  end

  it 'logs that a stored GET response is fresh' do
    client.get('get')
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /get] fresh') }
    client.get('get')
  end

  it 'sends the "Last-Modified" header on response validation' do
    client.get('timestamped')
    expect(client.get('timestamped').body).to eq('1')
  end

  it 'logs that the request with "Last-Modified" was revalidated' do
    client.get('timestamped')
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /timestamped] must_revalidate, valid, store') }
    expect(client.get('timestamped').body).to eq('1')
  end

  it 'sends the "If-None-Match" header on response validation' do
    client.get('etag')
    expect(client.get('etag').body).to eq('1')
  end

  it 'logs that the request with "ETag" was revalidated' do
    client.get('etag')
    expect(logger).to receive(:debug) { |&block| expect(block.call).to eq('HTTP Cache: [GET /etag] must_revalidate, valid, store') }
    expect(client.get('etag').body).to eq('1')
  end

  it 'maintains the "Date" header for cached responses' do
    first_date = client.get('get').headers['Date']
    second_date = client.get('get').headers['Date']
    expect(first_date).to eq(second_date)
  end

  it 'preserves an old "Date" header if present' do
    date = client.get('yesterday').headers['Date']
    expect(date).to match(/^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT$/)
  end

  it 'updates the "Cache-Control" header when a response is validated' do
    first_cache_control  = client.get('etag').headers['Cache-Control']
    second_cache_control = client.get('etag').headers['Cache-Control']
    expect(first_cache_control).not_to eql(second_cache_control)
  end

  it 'updates the "Date" header when a response is validated' do
    first_date  = client.get('etag').headers['Date']
    second_date = client.get('etag').headers['Date']
    expect(first_date).not_to eql(second_date)
  end

  it 'updates the "Expires" header when a response is validated' do
    first_expires  = client.get('etag').headers['Expires']
    second_expires = client.get('etag').headers['Expires']
    expect(first_expires).not_to eql(second_expires)
  end

  it 'updates the "Vary" header when a response is validated' do
    first_vary  = client.get('etag').headers['Vary']
    second_vary = client.get('etag').headers['Vary']
    expect(first_vary).not_to eql(second_vary)
  end

  it 'caches non-stale response with "must-revalidate" directive' do
    client.get('must-revalidate')
    expect(client.get('must-revalidate').body).to eq('1')
  end

  describe 'Configuration options' do
    let(:app) { double('it is an app!') }

    it 'uses the options to create a Cache Store' do
      store = double(read: nil, write: nil)

      expect(Faraday::HttpCache::Strategies::ByUrl).to receive(:new).with(hash_including(store: store))
      Faraday::HttpCache.new(app, store: store)
    end
  end
end
