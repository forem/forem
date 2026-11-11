require "rails_helper"

RSpec.describe Organization do
  before do
    allow(FastlyConfig::CustomDomainDictionary).to receive(:configured?).and_return(true)
    allow(Organizations::SyncCustomDomainDictionaryWorker).to receive(:perform_async)
  end

  it "enqueues dictionary sync when custom_domain is added or changed" do
    org = create(:organization, slug: "acme", custom_domain: nil)
    expect(Organizations::SyncCustomDomainDictionaryWorker).not_to have_received(:perform_async)

    org.update!(custom_domain: "blog.acme.com")
    expect(Organizations::SyncCustomDomainDictionaryWorker).to have_received(:perform_async).with(
      org.id,
      nil,
      nil,
    )

    org.update!(custom_domain: "news.acme.com")
    expect(Organizations::SyncCustomDomainDictionaryWorker).to have_received(:perform_async).with(
      org.id,
      nil,
      "blog.acme.com",
    )
  end

  it "enqueues dictionary sync with previous slug when slug changes on a custom-domain org" do
    org = create(:organization, slug: "acmeold", custom_domain: "blog.acme.com")
    allow(Organizations::SyncCustomDomainDictionaryWorker).to receive(:perform_async)

    org.update!(slug: "acmenew")

    expect(Organizations::SyncCustomDomainDictionaryWorker).to have_received(:perform_async).with(
      org.id,
      "acmeold",
      nil,
    )
  end

  it "enqueues dictionary cleanup when a custom-domain org is destroyed" do
    org = create(:organization, slug: "acmedestroy", custom_domain: "blog.acme.com")
    allow(Organizations::SyncCustomDomainDictionaryWorker).to receive(:perform_async)

    org.destroy!

    expect(Organizations::SyncCustomDomainDictionaryWorker).to have_received(:perform_async).with(
      org.id,
      "acmedestroy",
      "blog.acme.com",
    )
  end
end
