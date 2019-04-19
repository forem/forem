require "rails_helper"

RSpec.describe Follows::CreateChatChannelJob, type: :job do
  include_examples "#enqueues_job", "create_chat_channel_after_follow", 3

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let!(:follow) { create(:follow, follower: user, followable: user2) }

    it "creates a chat channel when mutual followers" do
      follow2 = create(:follow, follower: user2, followable: user)

      # Follow has an after_create callback that creates a channel between the two users,
      # so to make sure this test is correct, we delete all channels right after
      ChatChannelMembership.delete_all
      ChatChannel.delete_all

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
