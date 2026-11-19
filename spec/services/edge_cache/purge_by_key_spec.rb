require "rails_helper"

RSpec.describe EdgeCache::PurgeByKey, type: :service do
  let(:purge_url) { "https://api.fastly.com/service/fake-service-id/purge" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
  end

  it "purges normalized, deduplicated surrogate keys in a single Fastly batch POST" do
    stub = stub_request(:post, purge_url)
      .with(
        headers: {
          "Fastly-Key" => "fake-key",
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        },
        body: { surrogate_keys: %w[key-1 key-2] }.to_json,
      )
      .to_return(status: 200, body: "{}")

    described_class.call(["key-1", [" key-2 ", nil, "", "key-1"]])

    expect(stub).to have_been_requested.once
  end

  it "includes the Fastly-Soft-Purge header when soft: true" do
    stub = stub_request(:post, purge_url)
      .with(
        headers: { "Fastly-Soft-Purge" => "1" },
        body: { surrogate_keys: %w[key-1] }.to_json,
      )
      .to_return(status: 200, body: "{}")

    described_class.call("key-1", soft: true)

    expect(stub).to have_been_requested.once
  end

  it "chunks batches exceeding 256 surrogate keys" do
    keys = (1..300).map { |i| "articles/#{i}" }
    first_batch = stub_request(:post, purge_url)
      .with(body: { surrogate_keys: keys.first(256) }.to_json)
      .to_return(status: 200, body: "{}")
    second_batch = stub_request(:post, purge_url)
      .with(body: { surrogate_keys: keys.last(44) }.to_json)
      .to_return(status: 200, body: "{}")

    described_class.call(keys)

    expect(first_batch).to have_been_requested.once
    expect(second_batch).to have_been_requested.once
  end

  it "does not make an HTTP request when keys normalize to empty" do
    allow(HTTParty).to receive(:post)

    described_class.call([nil, "", "   "])

    expect(HTTParty).not_to have_received(:post)
  end

  it "does not evaluate lazy fallback_paths when Fastly is configured" do
    stub_request(:post, purge_url).to_return(status: 200, body: "{}")
    called = false
    lazy_paths = lambda do
      called = true
      ["/a"]
    end

    described_class.call("key-1", fallback_paths: lazy_paths)

    expect(called).to be(false)
  end

  it "logs and records stats when Fastly responds with a non-2xx status", :aggregate_failures do
    stub_request(:post, purge_url).to_return(status: 403, body: "Forbidden")
    allow(ForemStatsClient).to receive(:increment)
    allow(Rails.logger).to receive(:warn)

    described_class.call("key-1")

    expect(ForemStatsClient).to have_received(:increment)
      .with("edgecache_purge_by_key.service_error", tags: ["status:403"])
    expect(Rails.logger).to have_received(:warn)
      .with(hash_including(message: "EdgeCache::PurgeByKey purge was rejected", status: 403))
  end

  it "reports exceptions and continues remaining batches when a request raises", :aggregate_failures do
    keys = (1..260).map { |i| "articles/#{i}" }
    allow(HTTParty).to receive(:post).and_invoke(
      ->(*_) { raise Net::OpenTimeout, "execution expired" },
      ->(*_) { instance_double(HTTParty::Response, success?: true) },
    )
    allow(Rails.error).to receive(:report)
    allow(ForemStatsClient).to receive(:increment)

    described_class.call(keys)

    expect(HTTParty).to have_received(:post).twice
    expect(Rails.error).to have_received(:report).with(instance_of(Net::OpenTimeout))
    expect(ForemStatsClient).to have_received(:increment)
      .with("edgecache_purge_by_key.service_error", tags: ["error_class:Net::OpenTimeout"])
  end

  context "when Fastly is not configured" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
      allow(HTTParty).to receive(:post)
      allow(EdgeCache::Bust).to receive(:call)
    end

    it "does nothing when fallback_paths is not given" do
      described_class.call("key-1")

      expect(HTTParty).not_to have_received(:post)
      expect(EdgeCache::Bust).not_to have_received(:call)
    end

    it "falls back to path busting when fallback_paths is provided" do
      described_class.call("key-1", fallback_paths: ["/profile_preview_cards/1"])

      expect(EdgeCache::Bust).to have_received(:call).with(["/profile_preview_cards/1"])
    end

    it "evaluates callable fallback_paths lazily when Fastly is not configured" do
      described_class.call("key-1", fallback_paths: -> { ["/lazy/1", "/lazy/2"] })

      expect(EdgeCache::Bust).to have_received(:call).with(["/lazy/1", "/lazy/2"])
    end
  end
end
