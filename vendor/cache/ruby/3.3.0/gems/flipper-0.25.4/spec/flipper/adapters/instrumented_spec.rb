require 'flipper/adapters/instrumented'
require 'flipper/instrumenters/memory'

RSpec.describe Flipper::Adapters::Instrumented do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }

  let(:feature) { flipper[:stats] }
  let(:gate) { feature.gate(:percentage_of_actors) }
  let(:thing) { flipper.actors(22) }

  subject do
    described_class.new(adapter, instrumenter: instrumenter)
  end

  it_should_behave_like 'a flipper adapter'

  it 'forwards missing methods to underlying adapter' do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    instrumented = described_class.new(adapter)
    expect(instrumented.foo).to eq(:foo)
  end

  describe '#name' do
    it 'is instrumented' do
      expect(subject.name).to be(:instrumented)
    end
  end

  describe '#get' do
    it 'records instrumentation' do
      result = subject.get(feature)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:get)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#get_multi' do
    it 'records instrumentation' do
      result = subject.get_multi([feature])

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:get_multi)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_names]).to eq([:stats])
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#enable' do
    it 'records instrumentation' do
      result = subject.enable(feature, gate, thing)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:enable)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:gate_name]).to eq(:percentage_of_actors)
      expect(event.payload[:thing_value]).to eq(22)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#disable' do
    it 'records instrumentation' do
      result = subject.disable(feature, gate, thing)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:disable)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:gate_name]).to eq(:percentage_of_actors)
      expect(event.payload[:thing_value]).to eq(22)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#add' do
    it 'records instrumentation' do
      result = subject.add(feature)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:add)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#remove' do
    it 'records instrumentation' do
      result = subject.remove(feature)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:remove)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#clear' do
    it 'records instrumentation' do
      result = subject.clear(feature)

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:clear)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:feature_name]).to eq(:stats)
      expect(event.payload[:result]).to be(result)
    end
  end

  describe '#features' do
    it 'records instrumentation' do
      result = subject.features

      event = instrumenter.events.last
      expect(event).not_to be_nil
      expect(event.name).to eq('adapter_operation.flipper')
      expect(event.payload[:operation]).to eq(:features)
      expect(event.payload[:adapter_name]).to eq(:memory)
      expect(event.payload[:result]).to be(result)
    end
  end
end
