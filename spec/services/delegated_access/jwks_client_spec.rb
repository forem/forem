require "rails_helper"

RSpec.describe DelegatedAccess::JwksClient do
  let(:uri) { URI("https://issuer.example.test/.well-known/jwks.json") }
  let(:response_class) { DelegatedAccess::JwksClient::NetHttpAdapter::Response }
  let(:response) do
    response_class.new(
      status: 200,
      headers: {
        "content-type" => "application/json; charset=utf-8"
      },
      body: { keys: [] }.to_json,
    )
  end
  let(:adapter) { instance_double(DelegatedAccess::JwksClient::NetHttpAdapter) }
  let(:client) { described_class.new(uri: uri, adapter: adapter) }

  before do
    unless adapter.is_a?(DelegatedAccess::JwksClient::NetHttpAdapter)
      allow(adapter).to receive(:get).and_return(response)
    end
  end

  it "fetches only the configured URI without credentials" do
    result = client.fetch

    expect(adapter).to have_received(:get).with(
      uri,
      headers: {
        "Accept" => "application/json",
        "User-Agent" => "Forem delegated-access JWKS verifier"
      },
    )
    expect(result).to eq(response.body)
  end

  it "rejects redirects and non-JSON responses" do
    invalid_responses = [
      response.dup.tap { |value| value.status = 302 },
      response.dup.tap { |value| value.headers = value.headers.except("content-type") },
    ]

    invalid_responses.each do |invalid_response|
      allow(adapter).to receive(:get).and_return(invalid_response)
      expect { client.fetch }.to raise_error(described_class::Error)
    end
  end

  describe DelegatedAccess::JwksClient::NetHttpAdapter do
    let(:adapter) { described_class.new }

    it "reads a small HTTPS response without adding authorization or cookie headers" do
      request = stub_request(:get, uri.to_s).to_return(status: 200, body: "{}")

      response = adapter.get(uri, headers: { "Accept" => "application/json" })

      expect(response).to have_attributes(status: 200, body: "{}")
      expect(request).to have_been_requested
      expect(
        a_request(:get, uri.to_s).with do |webmock_request|
          !webmock_request.headers.key?("Authorization") && !webmock_request.headers.key?("Cookie")
        end,
      ).to have_been_made
    end

    it "rejects a response larger than the configured bound" do
      stub_request(:get, uri.to_s).to_return(status: 200, body: "x" * 65_537)

      expect { adapter.get(uri, headers: {}) }.to raise_error(DelegatedAccess::JwksClient::Error)
    end
  end
end
