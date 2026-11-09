require "rails_helper"

RSpec.describe EdgeCache::PurgeByKey, type: :service do
  let(:fastly_service) { instance_double(Fastly::Service) }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return(nil)
    allow(Fastly).to receive(:new).and_return(instance_double(Fastly))
    allow(Fastly::Service).to receive(:new).and_return(fastly_service)
    allow(fastly_service).to receive(:purge_by_key)
  end

  it "purges each surrogate key" do
    described_class.call(%w[key-1 key-2])
    expect(fastly_service).to have_received(:purge_by_key).with("key-1", false)
    expect(fastly_service).to have_received(:purge_by_key).with("key-2", false)
  end

  it "does nothing when fastly is not configured" do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)

    described_class.call("key-1")
    expect(fastly_service).not_to have_received(:purge_by_key)
  end

  it "falls back to path busting when fastly is not configured" do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
    allow(EdgeCache::Bust).to receive(:call)

    described_class.call("key-1", fallback_paths: ["/profile_preview_cards/1"])

    expect(EdgeCache::Bust).to have_received(:call).with(["/profile_preview_cards/1"])
  end

  context "when Cloudflare is configured instead of Fastly" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return("fake-cf-token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return("fake-zone-id")
    end

    it "purges surrogate keys as Cloudflare cache tags" do
      response = instance_double(HTTParty::Response, success?: true, code: 200)
      allow(HTTParty).to receive(:post).and_return(response)

      described_class.call(%w[articles/1 articles/2])

      expect(HTTParty).to have_received(:post).with(
        "https://api.cloudflare.com/client/v4/zones/fake-zone-id/purge_cache",
        headers: hash_including(
          "Authorization" => "Bearer fake-cf-token",
          "Content-Type" => "application/json",
        ),
        body: { tags: %w[articles/1 articles/2] }.to_json,
      )
    end

    it "falls back to path busting when Cloudflare tag purge fails and fallback_paths are provided" do
      response = instance_double(HTTParty::Response, success?: false, code: 403)
      allow(HTTParty).to receive(:post).and_return(response)
      allow(ForemStatsClient).to receive(:increment)
      allow(EdgeCache::Bust).to receive(:call)

      described_class.call("key-1", fallback_paths: ["/profile_preview_cards/1"])

      expect(ForemStatsClient).to have_received(:increment).with(
        "edgecache_purge_by_key.service_error",
        tags: ["provider:cloudflare", "status:403"],
      )
      expect(EdgeCache::Bust).to have_received(:call).with(["/profile_preview_cards/1"])
    end
  end
end
