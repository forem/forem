describe KnapsackPro::Client::API::V1::BuildSubsets do
  describe '.create' do
    let(:commit_hash) { double }
    let(:branch) { double }
    let(:node_total) { double }
    let(:node_index) { double }
    let(:test_files) { double }

    subject do
      described_class.create(
        commit_hash: commit_hash,
        branch: branch,
        node_total: node_total,
        node_index: node_index,
        test_files: test_files
      )
    end

    it do
      action = double
      expect(KnapsackPro::Client::API::Action).to receive(:new).with({
        endpoint_path: '/v1/build_subsets',
        http_method: :post,
        request_hash: {
          commit_hash: commit_hash,
          branch: branch,
          node_total: node_total,
          node_index: node_index,
          test_files: test_files
        }
      }).and_return(action)
      expect(subject).to eq action
    end
  end
end
