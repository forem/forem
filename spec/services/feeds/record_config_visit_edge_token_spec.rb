require "rails_helper"

RSpec.describe Feeds::RecordConfigVisit, type: :service do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:subforem) { create(:subforem, domain: "edge-visit.example.com") }
  let(:feed_config) { create(:feed_config, archived: false, feed_impression_users_count: 10) }
  let(:secret) { "edge-visit-test-secret" }
  let(:host) { "edge-visit.example.com" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_EDGE_FEED_SECRET").and_return(secret)
    allow(Settings::UserExperience).to receive_messages(
      feed_config_sticky_hours: 12,
      feed_config_sticky_percentage: 100,
      feed_config_repeat_visit_minutes: 30,
    )
  end

  it "ignores edge visit tokens when :fastly_edge_feed_mirror is disabled" do
    FeatureFlag.disable(:fastly_edge_feed_mirror)
    token = EdgeFeed::TokenSigner.issue_visit_token(
      user_id: user.id,
      subforem_id: subforem.id,
      feed_config_id: feed_config.id,
      expires_at: 6.hours.from_now,
      host: host,
    )

    result = described_class.call(
      token: token,
      event_id: SecureRandom.uuid,
      user_id: user.id,
      host: host,
      subforem_id: subforem.id,
    )

    expect(result).to be_nil
    expect(FeedConfigAssignment.where(user: user, subforem: subforem)).to be_empty
  end

  it "lazily creates FeedConfigAssignment and credits repeat visits across cooldown intervals" do
    FeatureFlag.enable(:fastly_edge_feed_mirror)
    expires_at = 6.hours.from_now.change(usec: 0)
    token = EdgeFeed::TokenSigner.issue_visit_token(
      user_id: user.id,
      subforem_id: subforem.id,
      feed_config_id: feed_config.id,
      expires_at: expires_at,
      host: host,
    )

    # First acknowledgement initializes last_rewarded_at without incrementing repeat_visits_count.
    first_next = described_class.call(
      token: token,
      event_id: SecureRandom.uuid,
      user_id: user.id,
      host: host,
      subforem_id: subforem.id,
    )
    expect(first_next).to be_present
    assignment = FeedConfigAssignment.find_by!(user: user, subforem: subforem)
    expect(assignment.feed_config_id).to eq(feed_config.id)
    expect(assignment.repeat_visits_count).to eq(0)

    # Second acknowledgement after cooldown increments repeat_visits_count and updates feed_config.
    assignment.update!(last_rewarded_at: 31.minutes.ago)
    second_next = described_class.call(
      token: token,
      event_id: SecureRandom.uuid,
      user_id: user.id,
      host: host,
      subforem_id: subforem.id,
    )
    expect(second_next).to be_present
    expect(assignment.reload.repeat_visits_count).to eq(1)
    expect(feed_config.reload.feed_repeat_visits_count).to eq(1)
  ensure
    FeatureFlag.disable(:fastly_edge_feed_mirror)
  end

  it "rejects edge visit tokens belonging to a different user or host" do
    FeatureFlag.enable(:fastly_edge_feed_mirror)
    token = EdgeFeed::TokenSigner.issue_visit_token(
      user_id: user.id,
      subforem_id: subforem.id,
      feed_config_id: feed_config.id,
      expires_at: 6.hours.from_now,
      host: host,
    )

    expect(
      described_class.call(
        token: token,
        event_id: SecureRandom.uuid,
        user_id: user.id + 1,
        host: host,
        subforem_id: subforem.id,
      ),
    ).to be_nil

    expect(
      described_class.call(
        token: token,
        event_id: SecureRandom.uuid,
        user_id: user.id,
        host: "evil.example.com",
        subforem_id: subforem.id,
      ),
    ).to be_nil
  ensure
    FeatureFlag.disable(:fastly_edge_feed_mirror)
  end
end
