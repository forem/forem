require "rails_helper"

RSpec.describe FastlyTls::Client do
  include WebMock::API

  let(:domain) { "blog.example.com" }
  let(:subscription_id) { "subs_123" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_PLATFORM_TLS_CONFIGURATION_ID").and_return("config_456")
  end

  describe ".create_subscription" do


    it "sends a POST request and returns the subscription ID" do
      stub_request(:post, "https://api.fastly.com/tls/subscriptions").
        with(headers: { "Fastly-Key" => "test_key", "Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json" }).
        to_return(status: 201, body: { data: { id: subscription_id, type: "tls_subscription", attributes: { state: "pending" } } }.to_json, headers: { "Content-Type" => "application/vnd.api+json" })

      expect(described_class.create_subscription(domain)).to eq(subscription_id)
    end

    it "raises an error on failure" do
      stub_request(:post, "https://api.fastly.com/tls/subscriptions").
        to_return(status: 400, body: { errors: [{ detail: "Bad Request" }] }.to_json, headers: { "Content-Type" => "application/vnd.api+json" })

      expect { described_class.create_subscription(domain) }.to raise_error(FastlyTls::Client::Error, "Fastly API Error: Bad Request")
    end
  end

  describe ".get_subscription" do


    it "fetches subscription details" do
      stub_request(:get, "https://api.fastly.com/tls/subscriptions/#{subscription_id}").
        with(headers: { "Fastly-Key" => "test_key" }).
        to_return(status: 200, body: { data: { id: subscription_id, type: "tls_subscription", attributes: { state: "issued" } } }.to_json, headers: { "Content-Type" => "application/vnd.api+json" })

      result = described_class.get_subscription(subscription_id)
      expect(result["attributes"]["state"]).to eq("issued")
    end
  end

  describe ".delete_subscription" do
    it "sends a DELETE request and returns true" do
      stub_request(:delete, "https://api.fastly.com/tls/subscriptions/#{subscription_id}").
        with(headers: { "Fastly-Key" => "test_key" }).
        to_return(status: 204, body: "", headers: {})

      expect(described_class.delete_subscription(subscription_id)).to be true
    end

    it "ignores 404 errors" do
      stub_request(:delete, "https://api.fastly.com/tls/subscriptions/#{subscription_id}").
        to_return(status: 404, body: { errors: [{ detail: "Not Found" }] }.to_json, headers: { "Content-Type" => "application/vnd.api+json" })

      expect(described_class.delete_subscription(subscription_id)).to be true
    end

    it "raises errors on other failures" do
      stub_request(:delete, "https://api.fastly.com/tls/subscriptions/#{subscription_id}").
        to_return(status: 500, body: { errors: [{ detail: "Server Error" }] }.to_json, headers: { "Content-Type" => "application/vnd.api+json" })

      expect { described_class.delete_subscription(subscription_id) }.to raise_error(FastlyTls::Client::Error)
    end
  end
end
