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

  describe "org_custom_domain Fastly dictionary sync hook" do
    let!(:organization) { create(:organization, slug: "syncorg", custom_domain: "blog.syncorg.com") }

    before do
      allow(FastlyConfig::CustomDomainDictionary).to receive(:configured?).and_return(true)
      allow(Organizations::SyncCustomDomainDictionaryWorker).to receive(:perform_async)
    end

    it "enqueues single-organization sync when org_custom_domain is toggled for an actor" do
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
      expect(Organizations::SyncCustomDomainDictionaryWorker).to have_received(:perform_async).with(organization.id)

      FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(organization))
      expect(Organizations::SyncCustomDomainDictionaryWorker)
        .to have_received(:perform_async).with(organization.id).twice
    end

    it "enqueues full dictionary sync when org_custom_domain is toggled globally or removed" do
      FeatureFlag.enable(:org_custom_domain)
      expect(Organizations::SyncCustomDomainDictionaryWorker)
        .to have_received(:perform_async).with(no_args).at_least(:once)

      allow(Organizations::SyncCustomDomainDictionaryWorker).to receive(:perform_async)
      FeatureFlag.remove(:org_custom_domain)
      expect(Organizations::SyncCustomDomainDictionaryWorker)
        .to have_received(:perform_async).with(no_args).at_least(:once)
    end

    it "does not enqueue dictionary sync for unrelated feature flags" do
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor.new(organization))
      expect(Organizations::SyncCustomDomainDictionaryWorker).not_to have_received(:perform_async)
    end
  end
end
