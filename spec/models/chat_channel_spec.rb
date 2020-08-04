require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  let(:chat_channel) { create(:chat_channel) }

  let(:users) { create_list(:user, 2) }

  describe "validations" do
    describe "builtin validations" do
      subject { chat_channel }

      it { is_expected.to have_many(:messages).dependent(:destroy) }
      it { is_expected.to have_many(:chat_channel_memberships).dependent(:destroy) }
      it { is_expected.to have_many(:users).through(:chat_channel_memberships) }

      it { is_expected.to validate_inclusion_of(:channel_type).in_array(%w[open invite_only direct]) }
      it { is_expected.to validate_inclusion_of(:status).in_array(%w[active inactive blocked]) }
      it { is_expected.to validate_length_of(:description).is_at_most(200) }
      it { is_expected.to validate_presence_of(:channel_type) }
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_uniqueness_of(:slug) }
    end
  end

  describe "#clear_channel" do
    before { allow(Pusher).to receive(:trigger) }

    it "clears chat" do
      create(:message, chat_channel: chat_channel, user: create(:user))
      chat_channel.reload
      expect(chat_channel.messages.size).to be_positive
      chat_channel.clear_channel
      expect(chat_channel.messages.size).to eq(0)
    end
  end

  describe "#create_with_users" do
    it "creates channel with users" do
      chat_channel = described_class.create_with_users(users: users)
      expect(chat_channel.users.size).to eq(users.size)
      expect(chat_channel.has_member?(users.first)).to be(true)
      expect(chat_channel.has_member?(users.last)).to be(true)
    end

    it "lists active memberships" do
      chat_channel = described_class.create_with_users(users: users)
      expect(chat_channel.active_users.size).to eq(users.size)
      expect(chat_channel.channel_users.size).to eq(users.size)
    end

    context "when direct channel is invalid" do
      it "raises an error if users are the same" do
        user = users.first
        expect { described_class.create_with_users(users: [user, user]) }.to raise_error("Invalid direct channel")
      end

      it "raises an error if more than 2 users" do
        more_users = users + [create(:user)]
        expect { described_class.create_with_users(users: more_users) }.to raise_error("Invalid direct channel")
      end
    end
  end

  describe "#active_users" do
    it "decreases active users if one leaves" do
      chat_channel = described_class.create_with_users(users: users)
      expect(chat_channel.active_users.size).to eq(users.size)
      expect(chat_channel.channel_users.size).to eq(users.size)
      ChatChannelMembership.last.update(status: "left_channel")
      expect(chat_channel.active_users.size).to eq(users.size - 1)
      expect(chat_channel.channel_users.size).to eq(users.size - 1)
    end
  end

  describe "#add_users" do
    it "adds users" do
      expect do
        chat_channel.add_users(users)
      end.to change(chat_channel.users, :count).by(users.size)
    end

    it "does not add users twice" do
      expect do
        chat_channel.add_users(users)
        chat_channel.add_users(users)
      end.to change(chat_channel.users, :count).by(users.size)
    end
  end

  describe "#remove_user" do
    it "removes a user from a channel" do
      chat_channel.add_users(users.first)
      expect(chat_channel.chat_channel_memberships.exists?(user_id: users.first.id)).to be(true)
      chat_channel.remove_user(users.first)
      expect(chat_channel.chat_channel_memberships.exists?(user_id: users.first.id)).to be(false)
    end
  end

  describe "#private_org_channel?" do
    it "detects private org channel if name matches" do
      chat_channel.channel_name = "@org private group chat"
      expect(chat_channel.private_org_channel?).to be(true)
    end

    it "detects not private org channel if name does not match" do
      chat_channel.channel_name = "@org magoo"
      expect(chat_channel.private_org_channel?).to be(false)
    end
  end
end
