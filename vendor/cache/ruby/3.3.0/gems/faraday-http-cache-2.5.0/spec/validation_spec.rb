# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache do
  let(:backend) { Faraday::Adapter::Test::Stubs.new }

  let(:client) do
    Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
      stack.use Faraday::HttpCache
      stack.adapter :test, backend
    end
  end

  it 'maintains the "Content-Type" header for cached responses' do
    backend.get('/test') { [200, { 'ETag' => '123ABC', 'Content-Type' => 'x' }, ''] }
    first_content_type = client.get('/test').headers['Content-Type']

    # The Content-Type header of the validation response should be ignored.
    backend.get('/test') { [304, { 'Content-Type' => 'y' }, ''] }
    second_content_type = client.get('/test').headers['Content-Type']

    expect(first_content_type).to eq('x')
    expect(second_content_type).to eq('x')
  end

  it 'maintains the "Content-Length" header for cached responses' do
    backend.get('/test') { [200, { 'ETag' => '123ABC', 'Content-Length' => 1 }, ''] }
    first_content_length = client.get('/test').headers['Content-Length']

    # The Content-Length header of the validation response should be ignored.
    backend.get('/test') { [304, { 'Content-Length' => 2 }, ''] }
    second_content_length = client.get('/test').headers['Content-Length']

    expect(first_content_length).to eq(1)
    expect(second_content_length).to eq(1)
  end
end
