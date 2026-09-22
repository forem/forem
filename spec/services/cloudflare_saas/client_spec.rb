require "rails_helper"

RSpec.describe CloudflareSaas::Client do
  include WebMock::API

  let(:zone_url) { "https://api.cloudflare.com/client/v4/zones/zone_123" }
  let(:hostname) { "blog.example.com" }
  let(:record) do
    {
      "id" => "hostname_abc",
      "hostname" => hostname,
      "status" => "pending",
      "ssl" => { "status" => "initializing" }
    }
  end
  let(:json_headers) { { "Content-Type" => "application/json" } }

  def error_body(message, code: 1000)
    { success: false, errors: [{ code: code, message: message }] }.to_json
  end

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("cf_token")
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("zone_123")
  end

  describe ".create_custom_hostname" do
    it "creates a hostname with an HTTP-validated DV certificate and returns the record" do
      request = stub_request(:post, "#{zone_url}/custom_hostnames")
        .with(
          headers: { "Authorization" => "Bearer cf_token", "Content-Type" => "application/json" },
          body: {
            hostname: hostname,
            ssl: { method: "http", type: "dv", settings: { min_tls_version: "1.2" } }
          }.to_json,
        )
        .to_return(status: 201, body: { success: true, result: record }.to_json, headers: json_headers)

      expect(described_class.create_custom_hostname(hostname)).to eq(record)
      expect(request).to have_been_requested
    end

    it "returns the existing record when the hostname already exists in the zone" do
      stub_request(:post, "#{zone_url}/custom_hostnames")
        .to_return(status: 409, body: error_body("Duplicate custom hostname found.", code: 1406), headers: json_headers)
      stub_request(:get, "#{zone_url}/custom_hostnames")
        .with(query: { hostname: hostname })
        .to_return(status: 200, body: { success: true, result: [record] }.to_json, headers: json_headers)

      expect(described_class.create_custom_hostname(hostname)).to eq(record)
    end

    it "raises a client error with the Cloudflare message when the hostname is rejected" do
      stub_request(:post, "#{zone_url}/custom_hostnames")
        .to_return(status: 400, body: error_body("Invalid custom hostname.", code: 1407), headers: json_headers)
      stub_request(:get, "#{zone_url}/custom_hostnames")
        .with(query: { hostname: hostname })
        .to_return(status: 200, body: { success: true, result: [] }.to_json, headers: json_headers)

      expect do
        described_class.create_custom_hostname(hostname)
      end.to raise_error(CloudflareSaas::Client::Error) { |error|
               expect(error.message).to eq("Cloudflare API Error: Invalid custom hostname.")
               expect(error).to be_client_error
             }
    end
  end

  describe ".get_custom_hostname" do
    it "returns the record" do
      stub_request(:get, "#{zone_url}/custom_hostnames/hostname_abc")
        .with(headers: { "Authorization" => "Bearer cf_token" })
        .to_return(status: 200, body: { success: true, result: record }.to_json, headers: json_headers)

      expect(described_class.get_custom_hostname("hostname_abc")).to eq(record)
    end

    it "returns nil when the hostname no longer exists" do
      stub_request(:get, "#{zone_url}/custom_hostnames/hostname_abc")
        .to_return(status: 404, body: error_body("Custom hostname not found.", code: 1436), headers: json_headers)

      expect(described_class.get_custom_hostname("hostname_abc")).to be_nil
    end

    it "raises a retryable error on server errors" do
      stub_request(:get, "#{zone_url}/custom_hostnames/hostname_abc")
        .to_return(status: 502, body: "", headers: {})

      expect do
        described_class.get_custom_hostname("hostname_abc")
      end.to raise_error(CloudflareSaas::Client::Error) { |error|
               expect(error).not_to be_client_error
             }
    end
  end

  describe ".find_custom_hostname" do
    it "only returns an exact hostname match" do
      other = record.merge("id" => "other", "hostname" => "www.blog.example.com")
      stub_request(:get, "#{zone_url}/custom_hostnames")
        .with(query: { hostname: hostname })
        .to_return(status: 200, body: { success: true, result: [other, record] }.to_json, headers: json_headers)

      expect(described_class.find_custom_hostname(hostname)["id"]).to eq("hostname_abc")
    end
  end

  describe ".delete_custom_hostname" do
    it "deletes the hostname" do
      request = stub_request(:delete, "#{zone_url}/custom_hostnames/hostname_abc")
        .to_return(status: 200, body: { success: true, result: { id: "hostname_abc" } }.to_json, headers: json_headers)

      expect(described_class.delete_custom_hostname("hostname_abc")).to be(true)
      expect(request).to have_been_requested
    end

    it "treats a missing hostname as deleted" do
      stub_request(:delete, "#{zone_url}/custom_hostnames/hostname_abc")
        .to_return(status: 404, body: error_body("Custom hostname not found."), headers: json_headers)

      expect(described_class.delete_custom_hostname("hostname_abc")).to be(true)
    end
  end
end
