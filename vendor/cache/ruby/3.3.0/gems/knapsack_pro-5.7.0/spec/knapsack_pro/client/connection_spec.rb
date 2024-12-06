shared_examples 'when request got response from API' do
  context 'when body response is JSON and API response code is 400' do
    let(:body) { '{"errors": "value"}' }
    let(:code) { '400' } # it must be string code

    before do
      expect(KnapsackPro).to receive(:logger).exactly(4).and_return(logger)
      expect(logger).to receive(:debug).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
      expect(logger).to receive(:debug).with('API request UUID: fake-uuid')
      expect(logger).to receive(:debug).with('API response:')
    end

    it do
      parsed_response = { 'errors' => 'value' }

      expect(logger).to receive(:error).with(parsed_response)

      expect(subject).to eq(parsed_response)
      expect(connection.success?).to be true
      expect(connection.errors?).to be true
    end
  end

  context 'when body response is JSON with build_distribution_id' do
    let(:body) { '{"build_distribution_id": "seed-uuid"}' }
    let(:code) { '200' } # it must be string code

    before do
      expect(KnapsackPro).to receive(:logger).exactly(5).and_return(logger)
      expect(logger).to receive(:debug).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
      expect(logger).to receive(:debug).with('API request UUID: fake-uuid')
      expect(logger).to receive(:debug).with("Test suite split seed: seed-uuid")
      expect(logger).to receive(:debug).with('API response:')
    end

    it do
      parsed_response = { 'build_distribution_id' => 'seed-uuid' }

      expect(logger).to receive(:debug).with(parsed_response)

      expect(subject).to eq(parsed_response)
      expect(connection.success?).to be true
      expect(connection.errors?).to be false
    end
  end

  context 'when body response is empty' do
    let(:body) { '' }
    let(:code) { '200' } # it must be string code

    before do
      expect(KnapsackPro).to receive(:logger).exactly(4).and_return(logger)
      expect(logger).to receive(:debug).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
      expect(logger).to receive(:debug).with('API request UUID: fake-uuid')
      expect(logger).to receive(:debug).with('API response:')
    end

    it do
      expect(logger).to receive(:debug).with('')

      expect(subject).to eq('')
      expect(connection.success?).to be true
      expect(connection.errors?).to be false
    end
  end
end

shared_examples 'when retry request' do
  context 'when body response is JSON and API response code is 500' do
    let(:body) { '{"error": "Internal Server Error"}' }
    let(:code) { '500' } # it must be string code

    before do
      expect(KnapsackPro).to receive(:logger).at_least(1).and_return(logger)
    end

    it do
      expect(logger).to receive(:debug).exactly(3).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
      expect(logger).to receive(:debug).exactly(3).with('API request UUID: fake-uuid')
      expect(logger).to receive(:debug).exactly(3).with('API response:')

      parsed_response = { 'error' => 'Internal Server Error' }

      expect(logger).to receive(:error).exactly(3).with(parsed_response)

      server_error = described_class::ServerError.new(parsed_response)
      expect(logger).to receive(:warn).exactly(3).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
      expect(logger).to receive(:warn).exactly(3).with('Request failed due to:')
      expect(logger).to receive(:warn).exactly(3).with(server_error.inspect)

      expect(logger).to receive(:warn).with("Wait for 8s before retrying the request to Knapsack Pro API.")
      expect(logger).to receive(:warn).with("6s left before retry...")
      expect(logger).to receive(:warn).with("4s left before retry...")
      expect(logger).to receive(:warn).with("2s left before retry...")
      expect(logger).to receive(:warn).with("Wait for 16s before retrying the request to Knapsack Pro API.")
      expect(logger).to receive(:warn).with("14s left before retry...")
      expect(logger).to receive(:warn).with("12s left before retry...")
      expect(logger).to receive(:warn).with("10s left before retry...")
      expect(logger).to receive(:warn).with("8s left before retry...")
      expect(logger).to receive(:warn).with("6s left before retry...")
      expect(logger).to receive(:warn).with("4s left before retry...")
      expect(logger).to receive(:warn).with("2s left before retry...")
      expect(Kernel).to receive(:sleep).exactly(12).with(2)

      expect(subject).to eq(parsed_response)

      expect(connection.success?).to be false
      expect(connection.errors?).to be true
    end

    context 'when max request retries defined' do
      before do
        expect(KnapsackPro::Config::Env).to receive(:max_request_retries).at_least(1).and_return(4)
      end

      it do
        expect(logger).to receive(:debug).exactly(4).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:debug).exactly(4).with('API request UUID: fake-uuid')
        expect(logger).to receive(:debug).exactly(4).with('API response:')

        parsed_response = { 'error' => 'Internal Server Error' }

        expect(logger).to receive(:error).exactly(4).with(parsed_response)

        server_error = described_class::ServerError.new(parsed_response)
        expect(logger).to receive(:warn).exactly(4).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:warn).exactly(4).with('Request failed due to:')
        expect(logger).to receive(:warn).exactly(4).with(server_error.inspect)

        expect(logger).to receive(:warn).with("Wait for 8s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 16s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("14s left before retry...")
        expect(logger).to receive(:warn).with("12s left before retry...")
        expect(logger).to receive(:warn).with("10s left before retry...")
        expect(logger).to receive(:warn).with("8s left before retry...")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 24s before retrying the request to Knapsack Pro API.")
        11.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(Kernel).to receive(:sleep).exactly(4+8+12).with(2)

        expect(subject).to eq(parsed_response)

        expect(connection.success?).to be false
        expect(connection.errors?).to be true
      end
    end

    context 'when Fallback Mode is disabled' do
      before do
        expect(KnapsackPro::Config::Env).to receive(:fallback_mode_enabled?).at_least(1).and_return(false)
      end

      it do
        expect(logger).to receive(:debug).exactly(6).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:debug).exactly(6).with('API request UUID: fake-uuid')
        expect(logger).to receive(:debug).exactly(6).with('API response:')

        parsed_response = { 'error' => 'Internal Server Error' }

        expect(logger).to receive(:error).exactly(6).with(parsed_response)

        server_error = described_class::ServerError.new(parsed_response)
        expect(logger).to receive(:warn).exactly(6).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:warn).exactly(6).with('Request failed due to:')
        expect(logger).to receive(:warn).exactly(6).with(server_error.inspect)

        expect(logger).to receive(:warn).with("Wait for 8s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 16s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("14s left before retry...")
        expect(logger).to receive(:warn).with("12s left before retry...")
        expect(logger).to receive(:warn).with("10s left before retry...")
        expect(logger).to receive(:warn).with("8s left before retry...")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 24s before retrying the request to Knapsack Pro API.")
        11.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(logger).to receive(:warn).with("Wait for 32s before retrying the request to Knapsack Pro API.")
        15.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(logger).to receive(:warn).with("Wait for 40s before retrying the request to Knapsack Pro API.")
        19.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(Kernel).to receive(:sleep).exactly(60).with(2)

        expect(subject).to eq(parsed_response)

        expect(connection.success?).to be false
        expect(connection.errors?).to be true
      end
    end

    context 'when Regular Mode' do
      before do
        expect(KnapsackPro::Config::Env).to receive(:regular_mode?).at_least(1).and_return(true)
      end

      it do
        expect(logger).to receive(:debug).exactly(6).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:debug).exactly(6).with('API request UUID: fake-uuid')
        expect(logger).to receive(:debug).exactly(6).with('API response:')

        parsed_response = { 'error' => 'Internal Server Error' }

        expect(logger).to receive(:error).exactly(6).with(parsed_response)

        server_error = described_class::ServerError.new(parsed_response)
        expect(logger).to receive(:warn).exactly(6).with("#{expected_http_method} http://api.knapsackpro.test:3000/v1/fake_endpoint")
        expect(logger).to receive(:warn).exactly(6).with('Request failed due to:')
        expect(logger).to receive(:warn).exactly(6).with(server_error.inspect)

        expect(logger).to receive(:warn).with("Wait for 8s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 16s before retrying the request to Knapsack Pro API.")
        expect(logger).to receive(:warn).with("14s left before retry...")
        expect(logger).to receive(:warn).with("12s left before retry...")
        expect(logger).to receive(:warn).with("10s left before retry...")
        expect(logger).to receive(:warn).with("8s left before retry...")
        expect(logger).to receive(:warn).with("6s left before retry...")
        expect(logger).to receive(:warn).with("4s left before retry...")
        expect(logger).to receive(:warn).with("2s left before retry...")

        expect(logger).to receive(:warn).with("Wait for 24s before retrying the request to Knapsack Pro API.")
        11.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(logger).to receive(:warn).with("Wait for 32s before retrying the request to Knapsack Pro API.")
        15.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(logger).to receive(:warn).with("Wait for 40s before retrying the request to Knapsack Pro API.")
        19.times do |i|
          expect(logger).to receive(:warn).with("#{(i+1)*2}s left before retry...")
        end

        expect(Kernel).to receive(:sleep).exactly(60).with(2)

        expect(subject).to eq(parsed_response)

        expect(connection.success?).to be false
        expect(connection.errors?).to be true
      end
    end
  end
end

describe KnapsackPro::Client::Connection do
  let(:endpoint_path) { '/v1/fake_endpoint' }
  let(:request_hash) { { fake: 'hash' } }
  let(:http_method) { :post }
  let(:action) do
    instance_double(KnapsackPro::Client::API::Action,
                    endpoint_path: endpoint_path,
                    http_method: http_method,
                    request_hash: request_hash)
  end
  let(:test_suite_token) { '3fa64859337f6e56409d49f865d13fd7' }
  let(:connection) { described_class.new(action) }
  let(:headers) do
    {
      'KNAPSACK_PRO_ENDPOINT' => 'http://api.knapsackpro.test:3000',
      'KNAPSACK_PRO_TEST_SUITE_TOKEN' => test_suite_token,
      'GITHUB_ACTIONS' => 'true',
    }
  end

  before do
    stub_const('ENV', headers)
  end

  describe '#call' do
    let(:logger) { instance_double(Logger) }
    let(:http) { instance_double(Net::HTTP) }
    let(:http_response) do
      header = { 'X-Request-Id' => 'fake-uuid' }
      instance_double(Net::HTTPOK, body: body, header: header, code: code)
    end

    subject { connection.call }

    before do
      expect(Net::HTTP).to receive(:new).with('api.knapsackpro.test', 3000).and_return(http)

      expect(http).to receive(:use_ssl=).with(false)
      expect(http).to receive(:open_timeout=).with(15)
      expect(http).to receive(:read_timeout=).with(15)
    end

    context 'when http method is POST on GitHub Actions' do
      let(:http_method) { :post }

      before do
        expect(http).to receive(:post).with(
          endpoint_path,
          request_hash.to_json,
          {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'KNAPSACK-PRO-CLIENT-NAME' => 'knapsack_pro-ruby',
            'KNAPSACK-PRO-CLIENT-VERSION' => KnapsackPro::VERSION,
            'KNAPSACK-PRO-TEST-SUITE-TOKEN' => test_suite_token,
            'KNAPSACK-PRO-CI-PROVIDER' => 'GitHub Actions',
          }
        ).and_return(http_response)
      end

      it_behaves_like 'when request got response from API' do
        let(:expected_http_method) { 'POST' }
      end
    end

    context 'when http method is POST and CI is undetected' do
      let(:http_method) { :post }

      let(:headers) do
        {
          'KNAPSACK_PRO_ENDPOINT' => 'http://api.knapsackpro.test:3000',
          'KNAPSACK_PRO_TEST_SUITE_TOKEN' => test_suite_token,
        }
      end

      before do
        expect(http).to receive(:post).with(
          anything,
          anything,
          hash_not_including('KNAPSACK-PRO-CI-PROVIDER')
        ).and_return(http_response)
      end

      it_behaves_like 'when request got response from API' do
        let(:expected_http_method) { 'POST' }
      end
    end

    context 'when http method is GET on GitHub Actions' do
      let(:http_method) { :get }

      before do
        uri = URI.parse("http://api.knapsackpro.test:3000#{endpoint_path}")
        uri.query = URI.encode_www_form(request_hash)
        expect(http).to receive(:get).with(
          uri,
          {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'KNAPSACK-PRO-CLIENT-NAME' => 'knapsack_pro-ruby',
            'KNAPSACK-PRO-CLIENT-VERSION' => KnapsackPro::VERSION,
            'KNAPSACK-PRO-TEST-SUITE-TOKEN' => test_suite_token,
            'KNAPSACK-PRO-CI-PROVIDER' => 'GitHub Actions',
          }
        ).and_return(http_response)
      end

      it_behaves_like 'when request got response from API' do
        let(:expected_http_method) { 'GET' }
      end
    end

    context 'when http method is GET and CI is undetected' do
      let(:http_method) { :get }

      let(:headers) do
        {
          'KNAPSACK_PRO_ENDPOINT' => 'http://api.knapsackpro.test:3000',
          'KNAPSACK_PRO_TEST_SUITE_TOKEN' => test_suite_token,
        }
      end

      before do
        expect(http).to receive(:get).with(
          anything,
          hash_not_including('KNAPSACK-PRO-CI-PROVIDER')
        ).and_return(http_response)
      end

      it_behaves_like 'when request got response from API' do
        let(:expected_http_method) { 'GET' }
      end
    end

    context 'when retry request for http method POST' do
      let(:http_method) { :post }

      before do
        expect(http).to receive(:post).at_least(3).with(
          endpoint_path,
          request_hash.to_json,
          {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'KNAPSACK-PRO-CLIENT-NAME' => 'knapsack_pro-ruby',
            'KNAPSACK-PRO-CLIENT-VERSION' => KnapsackPro::VERSION,
            'KNAPSACK-PRO-TEST-SUITE-TOKEN' => test_suite_token,
            'KNAPSACK-PRO-CI-PROVIDER' => 'GitHub Actions',
          }
        ).and_return(http_response)
      end

      it_behaves_like 'when retry request' do
        let(:expected_http_method) { 'POST' }
      end
    end

    context 'when retry request for http method GET' do
      let(:http_method) { :get }

      before do
        uri = URI.parse("http://api.knapsackpro.test:3000#{endpoint_path}")
        uri.query = URI.encode_www_form(request_hash)
        expect(http).to receive(:get).at_least(3).with(
          uri,
          {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'KNAPSACK-PRO-CLIENT-NAME' => 'knapsack_pro-ruby',
            'KNAPSACK-PRO-CLIENT-VERSION' => KnapsackPro::VERSION,
            'KNAPSACK-PRO-TEST-SUITE-TOKEN' => test_suite_token,
            'KNAPSACK-PRO-CI-PROVIDER' => 'GitHub Actions',
          }
        ).and_return(http_response)
      end

      it_behaves_like 'when retry request' do
        let(:expected_http_method) { 'GET' }
      end
    end
  end

  describe '#success?' do
    subject { connection.success? }

    before do
      allow(connection).to receive(:response_body).and_return(response_body)
    end

    context 'when response has no value' do
      let(:response_body) { nil }

      it { should be false }
    end

    context 'when response has value' do
      let(:response_body) do
        { 'fake' => 'response' }
      end

      before do
        http_response = double(code: code)
        allow(connection).to receive(:http_response).and_return(http_response)
      end

      context 'when response code is 200' do
        let(:code) { '200' } # it must be string code

        it { should be true }
      end

      context 'when response code is 300' do
        let(:code) { '300' } # it must be string code

        it { should be true }
      end

      context 'when response code is 400' do
        let(:code) { '400' } # it must be string code

        it { should be true }
      end

      context 'when response code is 500' do
        let(:code) { '500' } # it must be string code

        it { should be false }
      end
    end
  end

  describe '#errors?' do
    subject { connection.errors? }

    before do
      allow(connection).to receive(:response_body).and_return(response_body)
    end

    context 'when response has no value' do
      let(:response_body) { nil }

      it { should be false }
    end

    context 'when response has value' do
      context 'when response has no errors' do
        let(:response_body) do
          { 'fake' => 'response' }
        end

        it { should be false }
      end

      context 'when response has errors' do
        let(:response_body) do
          { 'errors' => [{ 'field' => 'is wrong' }] }
        end

        it { should be true }
      end

      context 'when response has error (i.e. internal server error)' do
        let(:response_body) do
          { 'error' => 'Internal Server Error' }
        end

        it { should be true }
      end
    end
  end

  describe '#server_error?' do
    subject { connection.server_error? }

    before do
      http_response = double(code: code)
      allow(connection).to receive(:http_response).and_return(http_response)
    end

    context 'when response code is 200' do
      let(:code) { '200' } # it must be string code

      it { should be false }
    end

    context 'when response code is 300' do
      let(:code) { '300' } # it must be string code

      it { should be false }
    end

    context 'when response code is 400' do
      let(:code) { '400' } # it must be string code

      it { should be false }
    end

    context 'when response code is 500' do
      let(:code) { '500' } # it must be string code

      it { should be true }
    end
  end
end
