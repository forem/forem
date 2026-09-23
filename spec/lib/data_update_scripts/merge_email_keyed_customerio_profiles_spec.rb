require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260923010000_merge_email_keyed_customerio_profiles.rb",
)

describe DataUpdateScripts::MergeEmailKeyedCustomerioProfiles do
  let(:track_client) { instance_double(Customerio::Client, batch: nil) }

  before do
    stub_const("CUSTOMERIO_TRACK_API", track_client)
    allow(ForemInstance).to receive(:customerio_track_enabled?).and_return(true)
    omniauth_mock_mlh_payload
  end

  def link(user, uid, at:)
    create(:identity, provider: "mlh", user: user, uid: uid, created_at: at)
  end

  it "merges the email-keyed profile of a user linked after signup into the linked person" do
    user = create(:user, created_at: 1.day.ago)
    link(user, "core-1", at: user.created_at + 30.seconds)

    described_class.new.run

    expect(track_client).to have_received(:batch).with(
      [{ type: "person", action: "merge", primary: { id: "core-1" }, secondary: { id: user.email } }],
    )
  end

  it "skips users linked before the rollout or not linked after signup" do
    old_user = create(:user, created_at: Time.zone.parse("2026-07-01"))
    link(old_user, "core-old", at: old_user.created_at + 30.seconds)
    create(:user, created_at: 1.day.ago)

    described_class.new.run

    expect(track_client).not_to have_received(:batch)
  end
end
