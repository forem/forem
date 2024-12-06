describe KnapsackPro::Crypto::BranchEncryptor do
  let(:branch) { 'feature-branch' }
  let(:encryptor) { described_class.new(branch) }

  describe '.call' do
    subject { described_class.call(branch) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:branch_encrypted?).and_return(branch_encrypted?)
    end

    context 'when branch encrypted flag enabled' do
      let(:branch_encrypted?) { true }
      let(:encryptor) { instance_double(described_class) }

      it do
        expect(described_class).to receive(:new).with(branch).and_return(encryptor)
        result = double
        expect(encryptor).to receive(:call).and_return(result)

        expect(subject).to eq result
      end
    end

    context 'when test files encrypted flag disabled' do
      let(:branch_encrypted?) { false }

      it { should eq branch }
    end
  end

  describe '#call' do
    subject { encryptor.call }

    context 'when encryptable branch name' do
      let(:branch) { 'feature-branch' }

      before do
        expect(KnapsackPro::Config::Env).to receive(:salt).at_least(1).and_return('123')
      end

      it { should eq '49e5bb1' }
    end

    described_class::NON_ENCRYPTABLE_BRANCHES.each do |branch_name|
      context "when non encryptable branch name: #{branch_name}" do
        let(:branch) { branch_name }

        it { should eq branch_name }
      end
    end
  end
end
