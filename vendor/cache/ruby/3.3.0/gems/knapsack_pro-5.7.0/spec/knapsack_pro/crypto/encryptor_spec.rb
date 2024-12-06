describe KnapsackPro::Crypto::Encryptor do
  let(:test_files) do
    [
      { 'path' => 'a_spec.rb', 'time_execution' => 1.2 },
      { 'path' => 'b_spec.rb', 'time_execution' => 2.3 },
    ]
  end

  let(:encryptor) { described_class.new(test_files) }

  describe '.call' do
    subject { described_class.call(test_files) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_files_encrypted?).and_return(test_files_encrypted?)
    end

    context 'when test files encrypted flag enabled' do
      let(:test_files_encrypted?) { true }
      let(:encryptor) { instance_double(described_class) }

      it do
        expect(described_class).to receive(:new).with(test_files).and_return(encryptor)
        result = double
        expect(encryptor).to receive(:call).and_return(result)

        expect(subject).to eq result
      end
    end

    context 'when test files encrypted flag disabled' do
      let(:test_files_encrypted?) { false }

      it { should eq test_files }
    end
  end

  describe '#call' do
    subject { encryptor.call }

    before do
      expect(KnapsackPro::Config::Env).to receive(:salt).at_least(1).and_return('123')
    end

    it "should not modify input test files array" do
      test_files_original = Marshal.load(Marshal.dump(test_files))
      subject
      expect(test_files).to eq test_files_original
    end

    it do
      should eq([
        { 'path' => '93131469d5aee8158473f9945847cd411ba975644b617897b7c33164adc55038', 'time_execution' => 1.2 },
        { 'path' => '716143a50194e2d2173b757b3418564f5efd12ce3c52332c02db60bb70c240bc', 'time_execution' => 2.3 },
      ])
    end
  end
end
