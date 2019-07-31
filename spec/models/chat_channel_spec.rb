require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  let(:chat_channel) { create(:chat_channel) }
  let(:message) { create(:chat_channel, message_id: chat_channel.id) }

  it { is_expected.to have_many(:messages) }
  it { is_expected.to validate_presence_of(:channel_type) }

  it "clears chat" do
    allow(Pusher).to receive(:trigger)
    chat_channel.clear_channel
    expect(chat_channel.messages.size).to eq(0)
  end

  it "creates channel with users" do
    chat_channel = described_class.create_with_users([create(:user), create(:user)])
    expect(chat_channel.users.size).to eq(2)
    expect(chat_channel.has_member?(User.first)).to eq(true)
  end

  it "lists active memberships" do
    chat_channel = described_class.create_with_users([create(:user), create(:user)])
    expect(chat_channel.active_users.size).to eq(2)
    expect(chat_channel.channel_users.size).to eq(2)
  end

  it "decreases active users if one leaves" do
    chat_channel = described_class.create_with_users([create(:user), create(:user)])
    ChatChannelMembership.last.update(status: "left_channel")
    expect(chat_channel.active_users.size).to eq(1)
    expect(chat_channel.channel_users.size).to eq(1)
  end
end
