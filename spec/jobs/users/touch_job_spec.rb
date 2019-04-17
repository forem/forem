require "rails_helper"

RSpec.describe Users::TouchJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      expect do
        described_class.perform_later(3)
      end.to have_enqueued_job.with(3).on_queue("touch_user")
    end

    it "touches a user" do
      timestamp = 1.day.ago
      user = create(:user, updated_at: timestamp, last_followed_at: timestamp)
      described_class.perform_now(user.id)
      expect(user.reload.updated_at).to be > timestamp
    end
  end
end
