require "rails_helper"

RSpec.describe CommunityLeaders::PruneInactive, type: :service do
  let(:inactivity_days) { Settings::UserExperience.community_leader_inactivity_days }
  let(:long_ago) { (inactivity_days + 1).days.ago }

  def stale_leader(level = :community_leader_level_1, **activity)
    leader = create(:user, level)
    leader.update_columns(created_at: long_ago, **User::ACTIVITY_TIMESTAMP_KEYS
      .index_with { nil }.symbolize_keys.merge(activity))
    backdate_roles(leader, long_ago)
    leader
  end

  def backdate_roles(user, at)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(
        ["UPDATE users_roles SET created_at = ? WHERE user_id = ?", at, user.id],
      ),
    )
  end

  it "revokes the role from a leader who has been quiet past the window" do
    leader = stale_leader

    described_class.call

    expect(leader.reload.community_leader?).to be false
  end

  it "reports how many leaders it pruned" do
    2.times { stale_leader }

    expect(described_class.call.pruned_count).to eq(2)
  end

  it "spares a leader who signed in recently" do
    leader = stale_leader(last_sign_in_at: 1.day.ago)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "spares a leader who is present without signing in" do
    leader = stale_leader(last_presence_at: 1.day.ago)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "spares a leader who commented recently" do
    leader = stale_leader(last_comment_at: 1.day.ago)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "spares a newly appointed leader with no activity history" do
    leader = create(:user, :community_leader_level_1)
    leader.update_columns(User::ACTIVITY_TIMESTAMP_KEYS.index_with { nil }.symbolize_keys)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "spares a long-dormant member recently appointed as leader" do
    leader = create(:user, :community_leader_level_1)
    leader.update_columns(created_at: long_ago, **User::ACTIVITY_TIMESTAMP_KEYS
      .index_with { nil }.symbolize_keys.merge(last_sign_in_at: long_ago))

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "prunes that same leader once the window has passed since appointment" do
    leader = create(:user, :community_leader_level_1)
    leader.update_columns(created_at: long_ago, **User::ACTIVITY_TIMESTAMP_KEYS
      .index_with { nil }.symbolize_keys.merge(last_sign_in_at: long_ago))
    backdate_roles(leader, long_ago)

    described_class.call

    expect(leader.reload.community_leader?).to be false
  end

  it "honors the configured window" do
    leader = stale_leader(last_presence_at: (inactivity_days + 60).days.ago)
    allow(Settings::UserExperience)
      .to receive(:community_leader_inactivity_days).and_return(inactivity_days + 120)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "does not honor a configured window shorter than the minimum" do
    leader = stale_leader(last_presence_at: 1.day.ago)
    allow(Settings::UserExperience).to receive(:community_leader_inactivity_days).and_return(0)

    described_class.call

    expect(leader.reload.community_leader?).to be true
  end

  it "prunes level 2 leaders too" do
    leader = stale_leader(:community_leader_level_2)

    described_class.call

    expect(leader.reload.community_leader?).to be false
  end

  it "leaves the trusted role in place" do
    leader = stale_leader
    leader.add_role(:trusted)

    described_class.call

    expect(leader.reload.has_trusted_role?).to be true
  end

  it "accepts a given window" do
    leader = stale_leader(last_presence_at: 10.days.ago)

    described_class.call(inactive_for: 5.days)

    expect(leader.reload.community_leader?).to be false
  end
end
