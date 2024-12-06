require 'active_support/cache'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/active_support_cache_store'

RSpec.describe Flipper::Adapters::ActiveSupportCacheStore do
  let(:memory_adapter) do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:write_through) { false }
  let(:adapter) { described_class.new(memory_adapter, cache, expires_in: 10.seconds, write_through: write_through) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

  before do
    cache.clear
  end

  it_should_behave_like 'a flipper adapter'

  describe '#remove' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.get(feature)
      adapter.remove(feature)
    end

    it 'expires feature and deletes the cache' do
      expect(cache.read(described_class.key_for(feature))).to be_nil
      expect(cache.exist?(described_class.key_for(feature))).to be(false)
      expect(feature).not_to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes an empty value to the cache' do
        expect(cache.read(described_class.key_for(feature))).to eq(adapter.default_config)
        expect(cache.exist?(described_class.key_for(feature))).to be(true)
        expect(feature).not_to be_enabled
      end
    end
  end

  describe '#enable' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.enable(feature, feature.gate(:boolean), flipper.boolean)
    end

    it 'enables feature and deletes the cache' do
      expect(cache.read(described_class.key_for(feature))).to be_nil
      expect(cache.exist?(described_class.key_for(feature))).to be(false)
      expect(feature).to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes to the cache' do
        expect(cache.exist?(described_class.key_for(feature))).to be(true)
        expect(cache.read(described_class.key_for(feature))).to include(boolean: 'true')
        expect(feature).to be_enabled
      end
    end
  end

  describe '#disable' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.disable(feature, feature.gate(:boolean), flipper.boolean)
    end

    it 'disables feature and deletes the cache' do
      expect(cache.read(described_class.key_for(feature))).to be_nil
      expect(cache.exist?(described_class.key_for(feature))).to be(false)
      expect(feature).not_to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes to the cache' do
        expect(cache.exist?(described_class.key_for(feature))).to be(true)
        expect(cache.read(described_class.key_for(feature))).to include(boolean: nil)
        expect(feature).not_to be_enabled
      end
    end
  end

  describe '#get_multi' do
    it 'warms uncached features' do
      stats = flipper[:stats]
      search = flipper[:search]
      other = flipper[:other]
      stats.enable
      search.enable

      memory_adapter.reset

      adapter.get(stats)
      expect(cache.read(described_class.key_for(search))).to be(nil)
      expect(cache.read(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.read(described_class.key_for(search))[:boolean]).to eq('true')
      expect(cache.read(described_class.key_for(other))[:boolean]).to be(nil)

      adapter.get_multi([stats, search, other])
      adapter.get_multi([stats, search, other])
      expect(memory_adapter.count(:get_multi)).to eq(1)
    end
  end

  describe '#get_all' do
    let(:stats) { flipper[:stats] }
    let(:search) { flipper[:search] }

    before do
      stats.enable
      search.add
    end

    it 'warms all features' do
      adapter.get_all
      expect(cache.read(described_class.key_for(stats))[:boolean]).to eq('true')
      expect(cache.read(described_class.key_for(search))[:boolean]).to be(nil)
      expect(cache.read(described_class::GetAllKey)).to be_within(2).of(Time.now.to_i)
    end

    it 'returns same result when already cached' do
      expect(adapter.get_all).to eq(adapter.get_all)
    end

    it 'only invokes one call to wrapped adapter' do
      memory_adapter.reset
      5.times { adapter.get_all }
      expect(memory_adapter.count(:get_all)).to eq(1)
    end
  end

  describe '#name' do
    it 'is active_support_cache_store' do
      expect(subject.name).to be(:active_support_cache_store)
    end
  end
end
