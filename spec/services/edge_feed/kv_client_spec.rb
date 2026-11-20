require "rails_helper"

RSpec.describe EdgeFeed::KvClient, type: :service do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:client) { described_class.new(api_key: "fastly-key", store_id: "store-123", cache: cache) }
  let(:ok_response) { instance_double(HTTParty::Response, success?: true, code: 200, body: "") }
  let(:error_response) { instance_double(HTTParty::Response, success?: false, code: 500, body: "boom") }

  describe "#put" do
    it "writes JSON payloads and deduplicates identical subsequent writes" do
      allow(HTTParty).to receive(:put).and_return(ok_response)

      expect(client.put("snapshot:1", { version: 1 })).to eq(:written)
      expect(client.put("snapshot:1", { version: 1 })).to eq(:unchanged)
      expect(client.put("snapshot:1", { version: 2 })).to eq(:written)

      expect(HTTParty).to have_received(:put).with(
        "https://api.fastly.com/resources/stores/kv/store-123/keys/snapshot%3A1",
        hash_including(
          headers: hash_including("Fastly-Key" => "fastly-key"),
          body: '{"version":1}',
        ),
      ).once
      expect(HTTParty).to have_received(:put).twice
    end

    it "returns :unconfigured without issuing HTTP requests when credentials are missing" do
      unconfigured = described_class.new(api_key: nil, store_id: nil, cache: cache)
      allow(HTTParty).to receive(:put)

      expect(unconfigured.put("snapshot:1", { version: 1 })).to eq(:unconfigured)
      expect(HTTParty).not_to have_received(:put)
    end

    it "returns :error and does not cache the digest when Fastly rejects the write" do
      allow(HTTParty).to receive(:put).and_return(error_response, ok_response)

      expect(client.put("snapshot:1", { version: 1 })).to eq(:error)
      expect(client.put("snapshot:1", { version: 1 })).to eq(:written)
      expect(HTTParty).to have_received(:put).twice
    end

    it "handles network timeouts gracefully" do
      allow(HTTParty).to receive(:put).and_raise(Net::ReadTimeout.new("timeout"))

      expect(client.put("snapshot:1", { version: 1 })).to eq(:error)
    end
  end

  describe "#delete" do
    it "deletes the key and clears the cached digest" do
      allow(HTTParty).to receive_messages(put: ok_response, delete: ok_response)

      expect(client.put("user:42", { user_id: 42 })).to eq(:written)
      expect(client.delete("user:42")).to eq(:deleted)
      expect(client.put("user:42", { user_id: 42 })).to eq(:written)
    end
  end
end
