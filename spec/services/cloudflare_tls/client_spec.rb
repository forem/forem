require "rails_helper"

RSpec.describe CloudflareTls::Client do
  include WebMock::API

  let(:domain) { "blog.example.com" }
  let(:subscription_id) { "cf_host_123" }
  let(:zone_id) { "zone_456" }
  let(:base_url) { "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return("test_cf_token")
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return(zone_id)
  end

  describe ".create_subscription" do
    it "sends a POST request to Cloudflare custom_hostnames and returns the custom hostname ID" do
      stub_request(:post, base_url)
        .with(
          headers: {
            "Authorization" => "Bearer test_cf_token",
            "Accept" => "application/json",
            "Content-Type" => "application/json"
          },
          body: { hostname: domain, ssl: { method: "http", type: "dv" } }.to_json,
        )
        .to_return(
          status: 201,
          body: { success: true, result: { id: subscription_id, ssl: { status: "pending_validation" } } }.to_json,
          headers: { "Content-Type" => "application/json" },
        )

      expect(described_class.create_subscription(domain)).to eq(subscription_id)
    end

    it "raises an error on failure" do
      stub_request(:post, base_url)
        .to_return(
          status: 400,
          body: { success: false, errors: [{ message: "Invalid hostname" }] }.to_json,
          headers: { "Content-Type" => "application/json" },
        )

      expect { described_class.create_subscription(domain) }.to raise_error(
        CloudflareTls::Client::Error,
        "Cloudflare API Error: Invalid hostname",
      )
    end
  end

  describe ".get_subscription" do
    it "normalizes Cloudflare active SSL status to issued" do
      stub_request(:get, "#{base_url}/#{subscription_id}")
        .with(headers: { "Authorization" => "Bearer test_cf_token" })
        .to_return(
          status: 200,
          body: { success: true, result: { id: subscription_id, ssl: { status: "active" } } }.to_json,
          headers: { "Content-Type" => "application/json" },
        )

      result = described_class.get_subscription(subscription_id)
      expect(result["attributes"]["state"]).to eq("issued")
    end

    it "normalizes Cloudflare pending_validation SSL status to pending" do
      stub_request(:get, "#{base_url}/#{subscription_id}")
        .to_return(
          status: 200,
          body: { success: true, result: { id: subscription_id, ssl: { status: "pending_validation" } } }.to_json,
          headers: { "Content-Type" => "application/json" },
        )

      result = described_class.get_subscription(subscription_id)
      expect(result["attributes"]["state"]).to eq("pending")
    end

    it "returns nil on 404" do
      stub_request(:get, "#{base_url}/#{subscription_id}")
        .to_return(status: 404, body: { success: false, errors: [{ message: "Not Found" }] }.to_json)

      expect(described_class.get_subscription(subscription_id)).to be_nil
    end
  end

  describe ".delete_subscription" do
    it "sends a DELETE request and returns true" do
      stub_request(:delete, "#{base_url}/#{subscription_id}")
        .with(headers: { "Authorization" => "Bearer test_cf_token" })
        .to_return(status: 200, body: { success: true, result: { id: subscription_id } }.to_json)

      expect(described_class.delete_subscription(subscription_id)).to be true
    end

    it "ignores 404 errors" do
      stub_request(:delete, "#{base_url}/#{subscription_id}")
        .to_return(status: 404, body: { success: false, errors: [{ message: "Not Found" }] }.to_json)

      expect(described_class.delete_subscription(subscription_id)).to be true
    end

    it "raises errors on other failures" do
      stub_request(:delete, "#{base_url}/#{subscription_id}")
        .to_return(status: 500, body: { success: false, errors: [{ message: "Internal Error" }] }.to_json)

      expect { described_class.delete_subscription(subscription_id) }.to raise_error(CloudflareTls::Client::Error)
    end
  end
end
