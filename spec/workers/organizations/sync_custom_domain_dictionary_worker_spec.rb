require "rails_helper"

RSpec.describe Organizations::SyncCustomDomainDictionaryWorker, type: :worker do
  before do
    allow(FastlyConfig::CustomDomainDictionary).to receive_messages(
      configured?: true,
      sync_all!: true,
      sync_organization!: true,
    )
  end

  it "runs a full sync when organization_id is nil" do
    described_class.new.perform

    expect(FastlyConfig::CustomDomainDictionary).to have_received(:sync_all!)
    expect(FastlyConfig::CustomDomainDictionary).not_to have_received(:sync_organization!)
  end

  it "syncs a single organization with previous slug and domain when organization_id is provided" do
    described_class.new.perform(42, "oldslug", "old.example.com")

    expect(FastlyConfig::CustomDomainDictionary).to have_received(:sync_organization!).with(
      42,
      previous_slug: "oldslug",
      previous_custom_domain: "old.example.com",
    )
  end

  it "no-ops when Fastly is not configured" do
    allow(FastlyConfig::CustomDomainDictionary).to receive(:configured?).and_return(false)

    described_class.new.perform(42)

    expect(FastlyConfig::CustomDomainDictionary).not_to have_received(:sync_organization!)
  end
end
