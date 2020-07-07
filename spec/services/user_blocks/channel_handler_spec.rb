require "rails_helper"

RSpec.describe UserBlocks::ChannelHandler, type: :service do
  before do
    create_list(:user, 2)
    blocker = User.first
    blocked = User.second
    chat_channel = create(:chat_channel, channel_type: "direct", status: "active",
                                         slug: "#{blocker.username}/#{blocked.username}")
    create(:chat_channel_membership, user: blocker, chat_channel: chat_channel)
    create(:chat_channel_membership, user: blocked, chat_channel: chat_channel)
    create(:user_block, blocker: blocker, blocked: blocked)
  end

  describe ".get_potential_chat_channel" do
    it "returns the correct channel" do
      expect(described_class.new(UserBlock.first).get_potential_chat_channel).to eq(ChatChannel.first)
    end
  end

  describe ".block_chat_channel" do
    it "updates the chat channel status to blocked" do
      described_class.new(UserBlock.first).block_chat_channel
      expect(ChatChannel.first.status).to eq "blocked"
    end

    it "removes the related chat channel memberships" do
      expect { described_class.new(UserBlock.first).block_chat_channel }.
        to change(ChatChannelMembership.where(status: "active"), :count).to 0
    end
  end

  describe ".unblock_chat_channel" do
    it "updates the chat channel status to be active" do
      described_class.new(UserBlock.first).unblock_chat_channel
      expect(ChatChannel.first.status).to eq "active"
    end

    it "updates the related chat channel memberships" do
      ChatChannelMembership.update_all(status: "left-channel")
      expect { described_class.new(UserBlock.first).unblock_chat_channel }.
        to change(ChatChannelMembership.where(status: "left-channel"), :count).to 0
    end
  end
end
