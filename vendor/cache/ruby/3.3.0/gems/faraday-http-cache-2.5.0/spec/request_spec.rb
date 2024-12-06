# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache::Request do
  subject { Faraday::HttpCache::Request.new method: method, url: url, headers: headers }
  let(:method) { :get }
  let(:url) { URI.parse('http://example.com/path/to/somewhere') }
  let(:headers) { {} }

  context 'a GET request' do
    it { should be_cacheable }
  end

  context 'a HEAD request' do
    let(:method) { :head }
    it { should be_cacheable }
  end

  context 'a POST request' do
    let(:method) { :post }
    it { should_not be_cacheable }
  end

  context 'a PUT request' do
    let(:method) { :put }
    it { should_not be_cacheable }
  end

  context 'an OPTIONS request' do
    let(:method) { :options }
    it { should_not be_cacheable }
  end

  context 'a DELETE request' do
    let(:method) { :delete }
    it { should_not be_cacheable }
  end

  context 'a TRACE request' do
    let(:method) { :trace }
    it { should_not be_cacheable }
  end

  context 'with "Cache-Control: no-store"' do
    let(:headers) { { 'Cache-Control' => 'no-store' } }
    it { should_not be_cacheable }
  end
end
