require "rails_helper"

RSpec.describe Users::TouchJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(3)
      end.to have_enqueued_job.with(3).on_queue("touch_user")
    end

    it "touches a user" do
      user = create(:user)
      user.update_columns(updated_at: Time.now - 1.day, last_followed_at: Time.now - 1.day)
      now = Time.now
      described_class.perform_now(user.id)
      user.reload
      expect(user.updated_at).to be >= now
    end
  end
end
