require "rails_helper"

RSpec.describe Flipper do
  let(:initializer_path) { Rails.root.join("config/initializers/flipper.rb") }

  after do
    load initializer_path
    described_class.instance = nil
  end

  it "uses ActiveRecord adapter directly when CACHE_FEATURE_FLAGS_SECONDS is not set" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CACHE_FEATURE_FLAGS_SECONDS", nil).and_return(nil)

    load initializer_path
    dsl = described_class.configuration.default

    expect(dsl.adapter.adapter).to be_a(Flipper::Adapters::ActiveRecord)
  end

  it "shares the underlying MemoryStore across threads when CACHE_FEATURE_FLAGS_SECONDS is set" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CACHE_FEATURE_FLAGS_SECONDS", nil).and_return("60")

    load initializer_path

    dsl_main = described_class.configuration.default
    dsl_worker_thread = Thread.new { described_class.configuration.default }.value

    expect(dsl_main).not_to equal(dsl_worker_thread)
    expect(dsl_main.adapter.adapter).to be_a(Flipper::Adapters::ActiveSupportCacheStore)
    expect(dsl_worker_thread.adapter.adapter).to be_a(Flipper::Adapters::ActiveSupportCacheStore)
    expect(dsl_main.adapter.adapter.cache).to equal(dsl_worker_thread.adapter.adapter.cache)
  end
end
