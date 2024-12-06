require 'flipper/adapters/failsafe'

RSpec.describe Flipper::Adapters::Failsafe do
  subject { described_class.new(memory_adapter, options) }

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:options) { {} }
  let(:flipper) { Flipper.new(subject) }

  it_should_behave_like 'a flipper adapter'

  context 'when disaster strikes' do
    before do
      expect(flipper[feature.name].enable).to be(true)

      (subject.methods - Object.methods).each do |method_name|
        allow(memory_adapter).to receive(method_name).and_raise(IOError)
      end
    end

    let(:feature) { Flipper::Feature.new(:my_feature, subject) }

    it { expect(subject.features).to eq(Set.new) }
    it { expect(feature.add).to eq(false) }
    it { expect(feature.remove).to eq(false) }
    it { expect(feature.clear).to eq(false) }
    it { expect(subject.get(feature)).to eq({}) }
    it { expect(subject.get_multi([feature])).to eq({}) }
    it { expect(subject.get_all).to eq({}) }
    it { expect(feature.enable).to eq(false) }
    it { expect(feature.disable).to eq(false) }

    context 'when used via Flipper' do
      it { expect(flipper.features).to eq(Set.new) }
      it { expect(flipper[feature.name].enabled?).to eq(false) }
      it { expect(flipper[feature.name].enable).to eq(false) }
      it { expect(flipper[feature.name].disable).to eq(false) }
    end

    context 'when there is a syntax error' do
      let(:test) { flipper[feature.name].enabled? }

      before do
        expect(memory_adapter).to receive(:get).and_raise(SyntaxError)
      end

      it 'does not catch this type of error' do
        expect { test }.to raise_error(SyntaxError)
      end

      context 'when configured to catch SyntaxError' do
        let(:options) { { errors: [SyntaxError] } }

        it { expect(test).to eq(false) }
      end
    end
  end
end
