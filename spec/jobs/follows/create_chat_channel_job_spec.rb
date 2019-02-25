require "rails_helper"

RSpec.describe Follows::CreateChatChannelJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(3)
      end.to have_enqueued_job.with(3).on_queue("create_chat_channel_after_follow")
    end
  end

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let!(:follow) { create(:follow, follower: user, followable: user2) }

    it "creates a chat channel when mutual followers" do
      follow2 = create(:follow, follower: user2, followable: user)
      expect do
        described_class.perform_now(follow2.id)
      end.to change(ChatChannel, :count).by(1)
    end

    it "doesn't create a chat channel when the follow is not mutual" do
      expect do
        described_class.perform_now(follow.id)
      end.not_to change(ChatChannel, :count)
    end

    it "doesn't fail if follow doesn't exist" do
      described_class.perform_now(Follow.maximum(:id).to_i + 1)
    end

    it "doesn't do anything if follow is not from user to user" do
      org_follow = create(:follow, follower: user, followable: create(:organization))
      expect do
        described_class.perform_now(org_follow.id)
      end.not_to change(ChatChannel, :count)
    end
  end
end
