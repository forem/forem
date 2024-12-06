require 'flipper/ui/decorators/gate'

RSpec.describe Flipper::UI::Decorators::Gate do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { build_flipper }
  let(:feature) { flipper[:some_awesome_feature] }
  let(:gate) { feature.gate(:boolean) }

  subject do
    described_class.new(gate, false)
  end

  describe '#initialize' do
    it 'sets gate' do
      expect(subject.gate).to be(gate)
    end

    it 'sets value' do
      expect(subject.value).to eq(false)
    end
  end

  describe '#as_json' do
    before do
      @result = subject.as_json
    end

    it 'returns Hash' do
      expect(@result).to be_instance_of(Hash)
    end

    it 'includes key' do
      expect(@result['key']).to eq('boolean')
    end

    it 'includes pretty name' do
      expect(@result['name']).to eq('boolean')
    end

    it 'includes value' do
      expect(@result['value']).to be(false)
    end
  end
end
