describe KnapsackPro::BuildDistributionFetcher do
  describe '.call' do
    subject { described_class.call }

    it do
      build_distribution_fetcher = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(build_distribution_fetcher)
      result = double
      expect(build_distribution_fetcher).to receive(:call).and_return(result)

      expect(subject).to eq result
    end
  end

  describe '#call' do
    let(:ci_node_total) { double }
    let(:ci_node_index) { double }
    let(:repository_adapter) { instance_double(KnapsackPro::RepositoryAdapters::EnvAdapter, commit_hash: double, branch: double) }

    subject { described_class.new.call }

    before do
      expect(KnapsackPro::RepositoryAdapterInitiator).to receive(:call).and_return(repository_adapter)

      expect(KnapsackPro::Config::Env).to receive(:ci_node_total).and_return(ci_node_total)
      expect(KnapsackPro::Config::Env).to receive(:ci_node_index).and_return(ci_node_index)

      action = double
      expect(KnapsackPro::Client::API::V1::BuildDistributions).to receive(:last).with({
        commit_hash: repository_adapter.commit_hash,
        branch: repository_adapter.branch,
        node_total: ci_node_total,
        node_index: ci_node_index,
      }).and_return(action)

      connection = instance_double(KnapsackPro::Client::Connection,
                                   call: response,
                                   success?: success?,
                                   errors?: errors?)
      expect(KnapsackPro::Client::Connection).to receive(:new).with(action).and_return(connection)
    end

    context 'when successful request to API' do
      let(:success?) { true }

      context 'when response has errors' do
        let(:errors?) { true }
        let(:response) { 'fake error response' }

        it do
          expect { subject }.to raise_error(ArgumentError, response)
        end
      end

      context 'when response has no errors' do
        let(:errors?) { false }
        let(:response) do
          {
            'build_distribution_id' => 'be2b95b1-1b8b-43a3-9d66-cabebbf135b8',
            'time_execution' => 2.5,
            'test_files' => [
              { 'path' => 'a_spec.rb', 'time_execution' => 1.5 },
              { 'path' => 'b_spec.rb', 'time_execution' => 1.0 },
            ]
          }
        end

        it { expect(subject).to be_a described_class::BuildDistributionEntity }
        it { expect(subject.time_execution).to eq 2.5 }
        it do
          expect(subject.test_files).to eq([
            { 'path' => 'a_spec.rb', 'time_execution' => 1.5 },
            { 'path' => 'b_spec.rb', 'time_execution' => 1.0 },
          ])
        end
      end
    end

    context 'when not successful request to API' do
      let(:success?) { false }
      let(:errors?) { false }
      let(:response) { double }

      it { expect(subject).to be_a described_class::BuildDistributionEntity }
      it { expect(subject.time_execution).to eq 0.0 }
      it { expect(subject.test_files).to eq([]) }
    end
  end
end
