describe KnapsackPro::RepositoryAdapters::EnvAdapter do
  it { should be_kind_of KnapsackPro::RepositoryAdapters::BaseAdapter }

  describe '#commit_hash' do
    let(:commit_hash) { double }

    subject { described_class.new.commit_hash }

    before do
      expect(KnapsackPro::Config::Env).to receive(:commit_hash).and_return(commit_hash)
    end

    it { should eq commit_hash }
  end

  describe '#branch' do
    let(:branch) { double }

    subject { described_class.new.branch }

    before do
      expect(KnapsackPro::Config::Env).to receive(:branch).and_return(branch)
    end

    it { should eq branch }
  end
end
