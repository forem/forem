require 'flipper/adapters/memoizable'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Adapters::Memoizable do
  let(:features_key) { described_class::FeaturesKey }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:cache)   { {} }

  subject { described_class.new(adapter, cache) }

  it_should_behave_like 'a flipper adapter'

  it 'forwards missing methods to underlying adapter' do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    memoizable = described_class.new(adapter)
    expect(memoizable.foo).to eq(:foo)
  end

  describe '#name' do
    it 'is instrumented' do
      expect(subject.name).to be(:memoizable)
    end
  end

  describe '#memoize=' do
    it 'sets value' do
      subject.memoize = true
      expect(subject.memoizing?).to eq(true)

      subject.memoize = false
      expect(subject.memoizing?).to eq(false)
    end

    it 'clears the local cache' do
      subject.cache['some'] = 'thing'
      subject.memoize = true
      expect(subject.cache).to be_empty
    end
  end

  describe '#memoizing?' do
    it 'returns true if enabled' do
      subject.memoize = true
      expect(subject.memoizing?).to eq(true)
    end

    it 'returns false if disabled' do
      subject.memoize = false
      expect(subject.memoizing?).to eq(false)
    end
  end

  describe '#get' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'memoizes feature' do
        feature = flipper[:stats]
        result = subject.get(feature)
        expect(cache[described_class.key_for(feature.key)]).to be(result)
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        feature = flipper[:stats]
        result = subject.get(feature)
        adapter_result = adapter.get(feature)
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe '#get_multi' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'memoizes features' do
        names = %i(stats shiny)
        features = names.map { |name| flipper[name] }
        results = subject.get_multi(features)
        features.each do |feature|
          expect(cache[described_class.key_for(feature.key)]).not_to be(nil)
          expect(cache[described_class.key_for(feature.key)]).to be(results[feature.key])
        end
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        names = %i(stats shiny)
        features = names.map { |name| flipper[name] }
        result = subject.get_multi(features)
        adapter_result = adapter.get_multi(features)
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe '#get_all' do
    context "with memoization enabled" do
      before do
        subject.memoize = true
      end

      it 'memoizes features' do
        names = %i(stats shiny)
        features = names.map { |name| flipper[name].tap(&:enable) }
        results = subject.get_all
        features.each do |feature|
          expect(cache[described_class.key_for(feature.key)]).not_to be(nil)
          expect(cache[described_class.key_for(feature.key)]).to be(results[feature.key])
        end
        expect(cache[subject.class::FeaturesKey]).to eq(names.map(&:to_s).to_set)
      end

      it 'only calls get_all once for memoized adapter' do
        adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
        cache = {}
        instance = described_class.new(adapter, cache)
        instance.memoize = true

        instance.get_all
        expect(adapter.count(:get_all)).to be(1)

        instance.get_all
        expect(adapter.count(:get_all)).to be(1)
      end

      it 'returns default_config for unknown feature keys' do
        first = subject.get_all
        expect(first['doesntexist']).to eq(subject.default_config)

        second = subject.get_all
        expect(second['doesntexist']).to eq(subject.default_config)
      end
    end

    context "with memoization disabled" do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        names = %i(stats shiny)
        names.map { |name| flipper[name].tap(&:enable) }
        result = subject.get_all
        adapter_result = adapter.get_all
        expect(result).to eq(adapter_result)
      end

      it 'calls get_all every time for memoized adapter' do
        adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
        cache = {}
        instance = described_class.new(adapter, cache)
        instance.memoize = false

        instance.get_all
        expect(adapter.count(:get_all)).to be(1)

        instance.get_all
        expect(adapter.count(:get_all)).to be(2)
      end

      it 'returns nil for unknown feature keys' do
        first = subject.get_all
        expect(first['doesntexist']).to be(nil)

        second = subject.get_all
        expect(second['doesntexist']).to be(nil)
      end
    end
  end

  describe '#enable' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'unmemoizes feature' do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        cache[described_class.key_for(feature.key)] = { some: 'thing' }
        subject.enable(feature, gate, flipper.bool)
        expect(cache[described_class.key_for(feature.key)]).to be_nil
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        result = subject.enable(feature, gate, flipper.bool)
        adapter_result = adapter.enable(feature, gate, flipper.bool)
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe '#disable' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'unmemoizes feature' do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        cache[described_class.key_for(feature.key)] = { some: 'thing' }
        subject.disable(feature, gate, flipper.bool)
        expect(cache[described_class.key_for(feature.key)]).to be_nil
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        feature = flipper[:stats]
        gate = feature.gate(:boolean)
        result = subject.disable(feature, gate, flipper.bool)
        adapter_result = adapter.disable(feature, gate, flipper.bool)
        expect(result).to eq(adapter_result)
      end
    end
  end

  describe '#features' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'memoizes features' do
        flipper[:stats].enable
        flipper[:search].disable
        result = subject.features
        expect(cache[:flipper_features]).to be(result)
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        expect(subject.features).to eq(adapter.features)
      end
    end
  end

  describe '#add' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'unmemoizes the known features' do
        cache[features_key] = { some: 'thing' }
        subject.add(flipper[:stats])
        expect(cache).to be_empty
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        expect(subject.add(flipper[:stats])).to eq(adapter.add(flipper[:stats]))
      end
    end
  end

  describe '#remove' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'unmemoizes the known features' do
        cache[features_key] = { some: 'thing' }
        subject.remove(flipper[:stats])
        expect(cache).to be_empty
      end

      it 'unmemoizes the feature' do
        feature = flipper[:stats]
        cache[described_class.key_for(feature.key)] = { some: 'thing' }
        subject.remove(feature)
        expect(cache[described_class.key_for(feature.key)]).to be_nil
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        expect(subject.remove(flipper[:stats])).to eq(adapter.remove(flipper[:stats]))
      end
    end
  end

  describe '#clear' do
    context 'with memoization enabled' do
      before do
        subject.memoize = true
      end

      it 'unmemoizes feature' do
        feature = flipper[:stats]
        cache[described_class.key_for(feature.key)] = { some: 'thing' }
        subject.clear(feature)
        expect(cache[described_class.key_for(feature.key)]).to be_nil
      end
    end

    context 'with memoization disabled' do
      before do
        subject.memoize = false
      end

      it 'returns result' do
        feature = flipper[:stats]
        expect(subject.clear(feature)).to eq(adapter.clear(feature))
      end
    end
  end
end
