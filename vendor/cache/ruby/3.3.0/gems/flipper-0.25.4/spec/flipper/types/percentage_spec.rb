require 'flipper/types/percentage_of_actors'

RSpec.describe Flipper::Types::Percentage do
  subject do
    described_class.new(5)
  end
  it_should_behave_like 'a percentage'

  describe '.wrap' do
    context 'with percentage instance' do
      it 'returns percentage instance' do
        expect(described_class.wrap(subject)).to eq(subject)
      end
    end

    context 'with Integer' do
      it 'returns percentage instance' do
        expect(described_class.wrap(subject.value)).to eq(subject)
      end
    end

    context 'with String' do
      it 'returns percentage instance' do
        expect(described_class.wrap(subject.value.to_s)).to eq(subject)
      end
    end
  end

  describe '#eql?' do
    it 'returns true for same class and value' do
      expect(subject.eql?(described_class.new(subject.value))).to eq(true)
    end

    it 'returns false for different value' do
      expect(subject.eql?(described_class.new(subject.value + 1))).to eq(false)
    end

    it 'returns false for different class' do
      expect(subject.eql?(Object.new)).to eq(false)
    end

    it 'is aliased to ==' do
      expect((subject == described_class.new(subject.value))).to eq(true)
    end
  end
end
