require "rails_helper"

RSpec.describe EdgeCache::BustPage, type: :service do
  let(:slug) { "slug" }
  let(:paths) do
    [
      "/page/#{slug}",
      "/#{slug}",
      "/#{slug}/",
    ]
  end

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "purges the page surrogate key with path fallbacks in a single call" do
    described_class.call(slug)

    expect(EdgeCache::PurgeByKey).to have_received(:call)
      .with(["show-page-#{slug}"], fallback_paths: paths)
      .once
  end

  context "when an organization is given" do
    let(:organization) { create(:organization) }
    let(:slug) { "#{organization.slug}/readme" }

    it "purges both page and organization surrogate keys in a single call" do
      described_class.call(slug, organization: organization)

      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with(
          ["show-page-#{slug}", organization.record_key],
          fallback_paths: [*paths, "/#{organization.slug}"],
        )
        .once
    end
  end
end
