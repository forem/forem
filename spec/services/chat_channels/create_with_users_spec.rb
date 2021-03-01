require "rails_helper"

RSpec.describe ChatChannels::CreateWithUsers, type: :service do
  let(:chat_channel) { create(:chat_channel) }
  let(:users) { create_list(:user, 2) }

  describe "#call" do
    it "creates channel with users" do
      chat_channel = described_class.call(users: users)
      expect(chat_channel.users.size).to eq(users.size)
      expect(chat_channel.has_member?(users.first)).to be(true)
      expect(chat_channel.has_member?(users.last)).to be(true)
    end

    it "lists active memberships" do
      chat_channel = described_class.call(users: users)
      expect(chat_channel.active_users.size).to eq(users.size)
      expect(chat_channel.channel_users.size).to eq(users.size)
    end

    context "when direct channel is invalid" do
      it "raises an error if users are the same" do
        user = users.first
        expect { described_class.call(users: [user, user]) }.to raise_error("Invalid direct channel")
      end

      it "raises an error if more than 2 users" do
        more_users = users + [create(:user)]
        expect { described_class.call(users: more_users) }.to raise_error("Invalid direct channel")
      end
    end
  end

  describe "#active_users" do
    it "decreases active users if one leaves" do
      chat_channel = described_class.call(users: users)
      expect(chat_channel.active_users.size).to eq(users.size)
      expect(chat_channel.channel_users.size).to eq(users.size)
      ChatChannelMembership.last.update(status: "left_channel")
      expect(chat_channel.active_users.size).to eq(users.size - 1)
      expect(chat_channel.channel_users.size).to eq(users.size - 1)
    end
  end
end
