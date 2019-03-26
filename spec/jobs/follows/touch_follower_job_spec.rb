require "rails_helper"

RSpec.describe Follows::TouchFollowerJob, type: :job do
  include_examples "#enqueues_job", "touch_follower", 3

  describe "#perform_now" do
    it "touches a follower" do
      user = create(:user)
      user.update_columns(updated_at: Time.now - 1.day, last_followed_at: Time.now - 1.day)
      now = Time.now
      follow = create(:follow, follower: user)

      described_class.perform_now(follow.id)
      user.reload

      expect(user.updated_at).to be >= now
      expect(user.last_followed_at).to be >= now
    end

    it "doesn't fail if follow doesn't exist" do
      described_class.perform_now(Follow.maximum(:id).to_i + 1)
    end
  end
end
