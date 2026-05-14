require "rails_helper"

RSpec.describe EdgeCache::PurgeByKey, type: :service do
  let(:fastly_service) { instance_double(Fastly::Service) }

  before do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
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
end
