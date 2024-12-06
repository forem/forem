describe KnapsackPro::Client::API::Action do
  let(:endpoint_path) { double }
  let(:http_method) { double }
  let(:request_hash) { double }

  subject do
    described_class.new(
      endpoint_path: endpoint_path,
      http_method: http_method,
      request_hash: request_hash
    )
  end

  its(:endpoint_path) { should eq endpoint_path }
  its(:http_method) { should eq http_method }
  its(:request_hash) { should eq request_hash }
end
