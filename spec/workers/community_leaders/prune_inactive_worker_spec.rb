require "rails_helper"

RSpec.describe CommunityLeaders::PruneInactiveWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "prunes leaders who have been quiet past the window" do
      long_ago = (Settings::UserExperience.community_leader_inactivity_days + 1).days.ago
      leader = create(:user, :community_leader_level_1)
      leader.update_columns(
        User::ACTIVITY_TIMESTAMP_KEYS.index_with { nil }.symbolize_keys
          .merge(created_at: long_ago),
      )
      # The window runs from appointment, so the role has to look old too.
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array(
          ["UPDATE users_roles SET created_at = ? WHERE user_id = ?", long_ago, leader.id],
        ),
      )

      worker.perform

      expect(leader.reload.community_leader?).to be false
    end

    it "leaves active leaders alone" do
      leader = create(:user, :community_leader_level_1)

      worker.perform

      expect(leader.reload.community_leader?).to be true
    end
  end
end
