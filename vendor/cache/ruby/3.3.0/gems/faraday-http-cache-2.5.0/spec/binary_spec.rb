# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache do
  let(:client) do
    Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
      stack.use :http_cache, serializer: Marshal
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end
  let(:data) { IO.binread File.expand_path('support/empty.png', __dir__) }

  it 'works fine with binary data' do
    expect(client.get('image').body).to eq data
    expect(client.get('image').body).to eq data
  end
end
