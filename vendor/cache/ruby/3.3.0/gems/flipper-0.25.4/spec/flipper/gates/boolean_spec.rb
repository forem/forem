RSpec.describe Flipper::Gates::Boolean do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(bool)
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(boolean: bool),
      thing: Flipper::Types::Actor.new(Flipper::Actor.new(1))
    )
  end

  describe '#enabled?' do
    context 'for true value' do
      it 'returns true' do
        expect(subject.enabled?(true)).to eq(true)
      end
    end

    context 'for false value' do
      it 'returns false' do
        expect(subject.enabled?(false)).to eq(false)
      end
    end
  end

  describe '#open?' do
    context 'for true value' do
      it 'returns true' do
        expect(subject.open?(context(true))).to be(true)
      end
    end

    context 'for false value' do
      it 'returns false' do
        expect(subject.open?(context(false))).to be(false)
      end
    end
  end

  describe '#protects?' do
    it 'returns true for boolean type' do
      expect(subject.protects?(Flipper::Types::Boolean.new(true))).to be(true)
    end

    it 'returns true for true' do
      expect(subject.protects?(true)).to be(true)
    end

    it 'returns true for false' do
      expect(subject.protects?(false)).to be(true)
    end
  end

  describe '#wrap' do
    it 'returns boolean type for boolean type' do
      expect(subject.wrap(Flipper::Types::Boolean.new(true)))
        .to be_instance_of(Flipper::Types::Boolean)
    end

    it 'returns boolean type for true' do
      expect(subject.wrap(true)).to be_instance_of(Flipper::Types::Boolean)
      expect(subject.wrap(true).value).to be(true)
    end

    it 'returns boolean type for true' do
      expect(subject.wrap(false)).to be_instance_of(Flipper::Types::Boolean)
      expect(subject.wrap(false).value).to be(false)
    end
  end
end
