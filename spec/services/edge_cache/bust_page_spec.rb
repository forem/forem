require "rails_helper"

RSpec.describe EdgeCache::BustPage, type: :service do
  let(:slug) { "slug" }
  let(:paths) do
    [
      "/page/#{slug}",
      "/#{slug}",
      "/#{slug}/",
      "/#{slug}?mode=embed",
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

  it "includes legacy redirect keys when a top-level page claims a former username" do
    former_user = create(:user)
    former_user.update_columns(old_username: slug)

    described_class.call(slug)

    expect(EdgeCache::PurgeByKey).to have_received(:call)
      .with(["show-page-#{slug}", former_user.profile_identity_record_key], fallback_paths: paths)
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

  context "when a user is given" do
    let(:user) { create(:user) }
    let(:slug) { "#{user.username}/embed/demo" }

    it "purges page and user surrogate keys alongside the mode=embed fallback path" do
      described_class.call(slug, user: user)

      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with(
          ["show-page-#{slug}", user.record_key, user.profile_identity_record_key],
          fallback_paths: [*paths, user.path],
        )
        .once
    end
  end
end
