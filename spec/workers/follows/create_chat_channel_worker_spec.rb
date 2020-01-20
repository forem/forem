require "rails_helper"

RSpec.describe Follows::CreateChatChannelWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with follow" do
      let_it_be(:user) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:follow) { create(:follow, follower: user, followable: user2) }

      it "creates a chat channel when mutual followers" do
        follow2 = create(:follow, follower: user2, followable: user)

        # Follow has an after_create callback that creates a channel between the two users,
        # so to make sure this test is correct, we delete all channels right after
        ChatChannelMembership.delete_all
        ChatChannel.delete_all

        expect do
          worker.perform(follow2.id)
        end.to change(ChatChannel, :count).by(1)
      end

      it "doesn't create a chat channel when the follow is not mutual" do
        expect do
          worker.perform(follow.id)
        end.not_to change(ChatChannel, :count)
      end

      it "doesn't do anything if follow is not from user to user" do
        org_follow = create(:follow, follower: user, followable: create(:organization))
        expect do
          worker.perform(org_follow.id)
        end.not_to change(ChatChannel, :count)
      end
    end

    context "without follow" do
      it "does not break" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
