# frozen_string_literal: true

require 'spec_helper'

describe Faraday::HttpCache::Strategies::BaseStrategy do
  subject(:strategy) { described_class.new }

  it 'uses a MemoryStore as a default store' do
    expect(Faraday::HttpCache::MemoryStore).to receive(:new).and_call_original
    strategy
  end

  context 'when the given store is not valid' do
    let(:store) { double(:wrong_store) }
    subject(:strategy) { described_class.new(store: store) }

    it 'raises an error' do
      expect { strategy }.to raise_error(ArgumentError)
    end
  end

  it 'raises an error when abstract methods are called' do
    expect { strategy.write(nil, nil) }.to raise_error(NotImplementedError)
    expect { strategy.read(nil) }.to raise_error(NotImplementedError)
    expect { strategy.delete(nil) }.to raise_error(NotImplementedError)
  end
end
