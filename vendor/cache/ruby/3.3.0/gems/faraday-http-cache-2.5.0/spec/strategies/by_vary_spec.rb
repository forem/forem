# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache::Strategies::ByVary do
  let(:vary_index_cache_key) { '64896419583e8022efeb21d0ece6e266c0e58b59' }
  let(:cache_key) { '978047698d156fe8642a86dbfaacc675917c9a22' }
  let(:vary) { 'Accept, Accept-Encoding, X-Requested-With' }
  let(:headers) { {'Accept' => 'text/html', 'Accept-Encoding' => 'gzip, deflate, br' } }
  let(:request) do
    env = {method: :get, url: 'http://test/index', headers: headers}
    double(env.merge(serializable_hash: env))
  end

  let(:response_payload) { {response_headers: {'Vary' => vary}} }

  let(:response) do
    instance_double(Faraday::HttpCache::Response, payload: response_payload, serializable_hash: response_payload)
  end

  let(:cache) { Faraday::HttpCache::MemoryStore.new }

  let(:strategy) { described_class.new(store: cache) }
  subject { strategy }

  describe 'storing responses' do
    shared_examples 'A strategy with serialization' do
      it 'writes the response object to the underlying cache' do
        entry = serializer.dump(response.serializable_hash)
        expect(cache).to receive(:write).with(vary_index_cache_key, vary)
        expect(cache).to receive(:write).with(cache_key, entry)
        subject.write(request, response)
      end
    end

    context 'with the JSON serializer' do
      let(:serializer) { JSON }
      it_behaves_like 'A strategy with serialization'

      context 'when ASCII characters in response cannot be converted to UTF-8', if: Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1') do
        let(:response_payload) do
          body = String.new("\u2665").force_encoding('ASCII-8BIT')
          super().merge('body' => body)
        end

        it 'raises and logs a warning' do
          logger = double(:logger, warn: nil)
          strategy = described_class.new(logger: logger)

          expect {
            strategy.write(request, response)
          }.to raise_error(::Encoding::UndefinedConversionError)
          expect(logger).to have_received(:warn).with(
            'Response could not be serialized: "\xE2" from ASCII-8BIT to UTF-8. Try using Marshal to serialize.'
          )
        end
      end

      context 'with reordered and doubled values in the vary' do
        let(:vary) { 'X-Requested-With,Accept,Accept-Encoding,Accept' }

        it_behaves_like 'A strategy with serialization'
      end
    end

    context 'with the Marshal serializer' do
      let(:vary_index_cache_key) { '6a7cb42440c10ef6edeb1826086a4d90b04103f0' }
      let(:cache_key) { 'c9edbf280da95d4cac5acda8b8109c0aba2a469a' }
      let(:serializer) { Marshal }
      let(:strategy) { described_class.new(store: cache, serializer: Marshal) }

      it_behaves_like 'A strategy with serialization'
    end
  end

  describe 'reading responses' do
    let(:strategy) { described_class.new(store: cache, serializer: serializer) }

    shared_examples 'A strategy with serialization' do
      it 'returns nil if the response is not cached' do
        expect(subject.read(request)).to be_nil
      end

      it 'decodes a stored response' do
        subject.write(request, response)

        expect(subject.read(request)).to be_a(Faraday::HttpCache::Response)
      end
    end

    context 'with the JSON serializer' do
      let(:serializer) { JSON }

      it_behaves_like 'A strategy with serialization'
    end

    context 'with the Marshal serializer' do
      let(:serializer) { Marshal }

      it_behaves_like 'A strategy with serialization'
    end
  end

  describe 'deleting responses' do
    it 'ignores delete method' do
      subject.write(request, response)
      subject.delete(request.url)
      expect(subject.read(request)).not_to be_nil
    end
  end

  describe 'remove age before caching and normalize max-age if non-zero age present' do
    it 'is fresh if the response still has some time to live' do
      headers = {
        'Age' => 6,
        'Cache-Control' => 'public, max-age=40',
        'Date' => (Time.now - 38).httpdate,
        'Expires' => (Time.now - 37).httpdate,
        'Last-Modified' => (Time.now - 300).httpdate
      }
      response = Faraday::HttpCache::Response.new(response_headers: headers)
      expect(response).to be_fresh
      subject.write(request, response)

      cached_response = subject.read(request)
      expect(cached_response.max_age).to eq(34)
      expect(cached_response).not_to be_fresh
    end

    it 'is fresh until cached and that 1 second elapses then the response is no longer fresh' do
      headers = {
        'Date' => (Time.now - 39).httpdate,
        'Expires' => (Time.now + 40).httpdate
      }

      response = Faraday::HttpCache::Response.new(response_headers: headers)
      expect(response).to be_fresh
      subject.write(request, response)

      sleep(1)
      cached_response = subject.read(request)
      expect(cached_response).not_to be_fresh
    end
  end
end
