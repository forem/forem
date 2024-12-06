require 'flipper/configuration'

RSpec.describe Flipper::Configuration do
  describe '#adapter' do
    it 'returns instance using Memory adapter' do
      expect(subject.adapter).to be_a(Flipper::Adapters::Memory)
    end

    it 'can be set' do
      instance = Flipper::Adapters::Memory.new
      expect(subject.adapter).not_to be(instance)
      subject.adapter { instance }
      expect(subject.adapter).to be(instance)
      # All adapters are wrapped in Memoizable
      expect(subject.default.adapter.adapter).to be(instance)
    end
  end

  describe '#default' do
    it 'returns instance using Memory adapter' do
      expect(subject.default).to be_a(Flipper::DSL)
      # All adapters are wrapped in Memoizable
      expect(subject.default.adapter.adapter).to be_a(Flipper::Adapters::Memory)
    end

    it 'can be set default' do
      instance = Flipper.new(Flipper::Adapters::Memory.new)
      expect(subject.default).not_to be(instance)
      subject.default { instance }
      expect(subject.default).to be(instance)
    end
  end
end
