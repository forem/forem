require "rails_helper"

RSpec.describe SegmentedUserRefreshWorker, type: :worker do
  let(:worker) { subject }

  # Sort of contriving a scenario where...
  #   User had not posted, then posted
  # So that:
  #   User was in group A and B, now belongs to B and C
  let!(:group_a) { create(:audience_segment, type_of: "no_posts_yet") }
  let!(:group_b) { create(:audience_segment, type_of: "trusted") }
  let!(:group_c) { create(:audience_segment, type_of: "posted") }
  let(:user) { create(:user, :trusted) }
  let(:user_id) { user.id }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "can confirm the scenario baseline by refreshing" do
    worker.perform(user_id)
    expect(group_a.segmented_users.pluck(:user_id)).to include(user_id)
    expect(group_b.segmented_users.pluck(:user_id)).to include(user_id)
    expect(group_c.segmented_users.pluck(:user_id)).not_to include(user_id)
  end

  context "when scenario is pre-built" do
    before do
      group_a.segmented_users.create! user: user
      group_b.segmented_users.create! user: user
      user.update articles_count: 1
    end

    it "refreshes a user's segmentation by id" do
      worker.perform(user_id)
      expect(group_a.segmented_users.pluck(:user_id)).not_to include(user_id)
      expect(group_b.segmented_users.pluck(:user_id)).to include(user_id)
      expect(group_c.segmented_users.pluck(:user_id)).to include(user_id)
    end
  end
end
