require "rails_helper"

RSpec.describe Users::FollowJob, type: :job do
  let(:user) { create(:user) }
  let(:followable) { create(:user) }

  describe "#perform_later" do
    it "enqueues the job" do
      assert_enqueued_with(job: described_class, args: [user, followable], queue: "users_follow") do
        described_class.perform_later(user, followable)
      end
    end
  end

  describe "#perform_now" do
    it "follows a user" do
      expect do
        described_class.perform_now(user, followable)
      end.to change(Follow, :count).by(1)
    end
  end
end
