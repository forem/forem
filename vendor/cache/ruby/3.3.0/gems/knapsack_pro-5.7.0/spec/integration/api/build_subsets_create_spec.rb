describe 'Request API /v1/build_subsets' do
  let(:valid_endpoint) { 'http://api.knapsackpro.test:3000' }
  let(:invalid_endpoint) { 'http://api.fake-knapsackpro.test:3000' }
  let(:valid_test_suite_token) { '3fa64859337f6e56409d49f865d13fd7' }
  let(:invalid_test_suite_token) { 'fake' }

  let(:action) do
    KnapsackPro::Client::API::V1::BuildSubsets.create(
      commit_hash: 'abcdefg',
      branch: 'master',
      node_total: '2',
      node_index: '1',
      test_files: [
        {
          'path' => 'a_spec.rb',
          'time_execution' => 1.2,
        },
        {
          'path' => 'b_spec.rb',
          'time_execution' => 0.3,
        }
      ],
    )
  end
  let(:connection) { KnapsackPro::Client::Connection.new(action) }
  let(:endpoint) { valid_endpoint }
  let(:test_suite_token) { valid_test_suite_token }

  before do
    stub_const('ENV', {
      'KNAPSACK_PRO_ENDPOINT' => endpoint,
      'KNAPSACK_PRO_TEST_SUITE_TOKEN' => test_suite_token,
    })
  end

  context 'when success' do
    it do
      VCR.use_cassette('api/v1/build_subsets/create/success') do
        response = connection.call
        puts response
      end

      expect(connection.errors?).to be false
      expect(connection.success?).to be true
    end
  end

  context 'when invalid test suite token' do
    let(:test_suite_token) { invalid_test_suite_token }

    it do
      VCR.use_cassette('api/v1/build_subsets/create/invalid_test_suite_token') do
        response = connection.call
        puts response
      end

      expect(connection.errors?).to be true
      expect(connection.success?).to be true
    end
  end

  context 'when timeout' do
    let(:endpoint) { invalid_endpoint }

    it do
      stub_const('KnapsackPro::Client::Connection::TIMEOUT', 0.01)
      stub_const('KnapsackPro::Client::Connection::REQUEST_RETRY_TIMEBOX', 0.01)
      VCR.use_cassette('api/v1/build_subsets/create/timeout') do
        response = connection.call
        puts response
      end

      expect(connection.errors?).to be false
      expect(connection.success?).to be false
    end
  end
end
