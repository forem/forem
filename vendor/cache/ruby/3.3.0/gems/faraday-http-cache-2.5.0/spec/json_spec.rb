# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache do
  let(:client) do
    Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
      stack.response :json, content_type: /\bjson$/
      stack.use :http_cache
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end

  it 'works fine with other middlewares' do
    client.get('clear')
    expect(client.get('json').body['count']).to eq(1)
    expect(client.get('json').body['count']).to eq(1)
  end
end
