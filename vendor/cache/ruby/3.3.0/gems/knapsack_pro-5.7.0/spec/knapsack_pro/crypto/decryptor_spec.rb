describe KnapsackPro::Crypto::Decryptor do
  let(:test_files) do
    [
      { 'path' => 'a_spec.rb' },
      { 'path' => 'b_spec.rb' },
    ]
  end
  let(:encrypted_test_files) do
    [
      { 'path' => '93131469d5aee8158473f9945847cd411ba975644b617897b7c33164adc55038', 'time_execution' => 1.2 },
      { 'path' => '716143a50194e2d2173b757b3418564f5efd12ce3c52332c02db60bb70c240bc', 'time_execution' => 2.3 },
    ]
  end

  let(:decryptor) { described_class.new(test_files, encrypted_test_files) }

  describe '.call' do
    subject { described_class.call(test_files, encrypted_test_files) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_files_encrypted?).and_return(test_files_encrypted?)
    end

    context 'when test files encrypted flag enabled' do
      let(:test_files_encrypted?) { true }
      let(:decryptor) { instance_double(described_class) }

      it do
        expect(described_class).to receive(:new).with(test_files, encrypted_test_files).and_return(decryptor)
        result = double
        expect(decryptor).to receive(:call).and_return(result)

        expect(subject).to eq result
      end
    end

    context 'when test files encrypted flag disabled' do
      let(:test_files_encrypted?) { false }
      let(:encrypted_test_files) { double }

      it { should eq encrypted_test_files }
    end
  end

  describe '#call' do
    subject { decryptor.call }

    before do
      expect(KnapsackPro::Config::Env).to receive(:salt).at_least(1).and_return('123')
    end

    it do
      should eq([
        { 'path' => 'a_spec.rb', 'time_execution' => 1.2 },
        { 'path' => 'b_spec.rb', 'time_execution' => 2.3 },
      ])
    end

    context 'when missing encrypted test file' do
      let(:encrypted_test_files) { [] }

      it do
        expect(subject).to eq []
      end
    end

    context 'when too many encrypted test files with the same encrypted path' do
      let(:encrypted_test_files) do
        [
          { 'path' => '93131469d5aee8158473f9945847cd411ba975644b617897b7c33164adc55038', 'time_execution' => 1.2 },
          { 'path' => '716143a50194e2d2173b757b3418564f5efd12ce3c52332c02db60bb70c240bc', 'time_execution' => 2.3 },
          { 'path' => '716143a50194e2d2173b757b3418564f5efd12ce3c52332c02db60bb70c240bc', 'time_execution' => 2.4 }, # duplicate
        ]
      end

      it do
        expect { subject }.to raise_error(KnapsackPro::Crypto::Decryptor::TooManyEncryptedTestFilesError)
      end
    end
  end
end
