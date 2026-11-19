require "rails_helper"

RSpec.describe EdgeCache::LegacySlugRedirectKeys, type: :service do
  it "returns surrogate keys of users and organizations that previously held the slug", :aggregate_failures do
    former_user = create(:user)
    former_user.update_columns(old_username: "claimedslug")
    former_org = create(:organization)
    former_org.update_columns(old_old_slug: "claimedslug")

    expect(described_class.call("claimedslug")).to contain_exactly(
      former_user.profile_identity_record_key,
      former_org.record_key,
    )
    expect(described_class.call("claimedslug", exclude_user_id: former_user.id)).to eq([former_org.record_key])
    expect(described_class.call("claimedslug", exclude_organization_id: former_org.id)).to eq(
      [former_user.profile_identity_record_key],
    )
  end

  it "returns empty for blank or nested slugs" do
    expect(described_class.call("")).to eq([])
    expect(described_class.call("org/readme")).to eq([])
  end

  it "enqueues a surrogate-key purge when a newly registered user claims a legacy username" do
    former_user = create(:user)
    former_user.update_columns(old_username: "freedhandle")

    sidekiq_assert_enqueued_with(
      job: EdgeCache::PurgeByKeyWorker,
      args: [[former_user.profile_identity_record_key], ["/freedhandle"]],
    ) do
      create(:user, username: "freedhandle")
    end
  end
end
