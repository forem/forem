describe KnapsackPro::RepositoryAdapterInitiator do
  describe '.call' do
    subject { described_class.call }

    before do
      expect(KnapsackPro::Config::Env).to receive(:repository_adapter).and_return(repository_adapter)
    end

    context 'when repository adapter is git' do
      let(:repository_adapter) { 'git' }

      it { should be_instance_of KnapsackPro::RepositoryAdapters::GitAdapter }
    end

    context 'when default repository adapter' do
      let(:repository_adapter) { nil }

      it { should be_instance_of KnapsackPro::RepositoryAdapters::EnvAdapter }
    end
  end
end
