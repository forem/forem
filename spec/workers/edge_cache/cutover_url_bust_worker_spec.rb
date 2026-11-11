require "rails_helper"

RSpec.describe EdgeCache::CutoverUrlBustWorker, type: :worker do
  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service")
    allow(EdgeCache::Bust::Fastly).to receive(:call)
  end

  it "purges each unique normalized path via EdgeCache::Bust::Fastly" do
    described_class.new.perform(["/tags", " /async_info/navigation_links ", "/tags"])

    expect(EdgeCache::Bust::Fastly).to have_received(:call).with("/tags").once
    expect(EdgeCache::Bust::Fastly).to have_received(:call).with("/async_info/navigation_links").once
  end

  it "reports errors and continues remaining paths when a purge raises", :aggregate_failures do
    allow(EdgeCache::Bust::Fastly).to receive(:call).with("/bad").and_raise(StandardError, "boom")
    allow(Rails.error).to receive(:report)

    described_class.new.perform(["/bad", "/good"])

    expect(Rails.error).to have_received(:report).with(instance_of(StandardError))
    expect(EdgeCache::Bust::Fastly).to have_received(:call).with("/good").once
  end
end
