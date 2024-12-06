RSpec.describe Flipper::Gates::Group do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(set)
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(groups: set),
      thing: Flipper::Types::Actor.new(Flipper::Actor.new('5'))
    )
  end

  describe '#open?' do
    context 'with a group in adapter, but not registered' do
      before do
        Flipper.register(:staff) { |_thing| true }
      end

      it 'ignores group' do
        thing = Flipper::Actor.new('5')
        expect(subject.open?(context(Set[:newbs, :staff]))).to be(true)
      end
    end

    context 'thing that does not respond to method in group block' do
      before do
        Flipper.register(:stinkers, &:stinker?)
      end

      it 'raises error' do
        expect do
          subject.open?(context(Set[:stinkers]))
        end.to raise_error(NoMethodError)
      end
    end
  end

  describe '#wrap' do
    it 'returns group instance for symbol' do
      group = Flipper.register(:admins) {}
      expect(subject.wrap(:admins)).to eq(group)
    end

    it 'returns group instance for group instance' do
      group = Flipper.register(:admins) {}
      expect(subject.wrap(group)).to eq(group)
    end
  end

  describe '#protects?' do
    it 'returns true for group' do
      group = Flipper.register(:admins) {}
      expect(subject.protects?(group)).to be(true)
    end

    it 'returns true for symbol' do
      expect(subject.protects?(:admins)).to be(true)
    end
  end
end
