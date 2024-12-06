describe KnapsackPro::TestCaseMergers::BaseMerger do
  describe '.call' do
    let(:test_files) { double }

    subject { described_class.call(adapter_class, test_files) }

    context 'when adapter_class is KnapsackPro::Adapters::RSpecAdapter' do
      let(:adapter_class) { KnapsackPro::Adapters::RSpecAdapter }

      it do
        result = double
        rspec_merger = instance_double(KnapsackPro::TestCaseMergers::RSpecMerger, call: result)
        expect(KnapsackPro::TestCaseMergers::RSpecMerger).to receive(:new).with(test_files).and_return(rspec_merger)

        expect(subject).to eq result
      end
    end

    context 'when adapter_class is unknown' do
      let(:adapter_class) { 'fake-adapter' }

      it do
        expect { subject }.to raise_error 'Test case merger does not exist for adapter_class: fake-adapter'
      end
    end
  end
end
