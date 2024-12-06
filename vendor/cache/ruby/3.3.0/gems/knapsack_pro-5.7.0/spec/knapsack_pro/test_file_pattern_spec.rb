describe KnapsackPro::TestFilePattern do
  describe '.call' do
    let(:adapter_class) { KnapsackPro::Adapters::BaseAdapter }

    subject { described_class.call(adapter_class) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_file_pattern).and_return(env_test_file_pattern)
    end

    context 'when ENV defined' do
      let(:env_test_file_pattern) { 'spec/**{,/*/**}/*_spec.rb' }

      it { should eq env_test_file_pattern }
    end

    context 'when ENV not defined' do
      let(:env_test_file_pattern) { nil }

      it { should eq 'test/**{,/*/**}/*_test.rb' }
    end
  end

  describe '#test_dir' do
    let(:adapter_class) { KnapsackPro::Adapters::BaseAdapter }

    subject { described_class.test_dir(adapter_class) }

    before do
      expect(described_class).to receive(:call).with(adapter_class).and_return(test_file_pattern)
    end

    context 'when default test file pattern' do
      let(:test_file_pattern) { 'spec/**{,/*/**}/*_spec.rb' }

      it 'extracts test directory from the pattern' do
        expect(subject).to eq 'spec'
      end
    end

    context 'when test file pattern has multiple patterns' do
      let(:test_file_pattern) { '{spec/*_spec.rb,spec2/controllers/**/*_spec.rb}' }

      it 'extracts test directory from the first pattern' do
        expect(subject).to eq 'spec'
      end
    end
  end
end
