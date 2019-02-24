require "rails_helper"

RSpec.describe Follows::TouchFollowerJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(3)
      end.to have_enqueued_job.with(3).on_queue("touch_follower")
    end

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
