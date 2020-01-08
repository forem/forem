require "rails_helper"

RSpec.describe Users::TouchWorker, type: :worker do
  describe "#perform_later" do
    let(:worker) { subject }

    it "touches a user" do
      timestamp = 1.day.ago
      user = create(:user, updated_at: timestamp, last_followed_at: timestamp)
      worker.perform(user.id)
      expect(user.reload.updated_at).to be > timestamp
    end
  end
end
