require "rails_helper"

RSpec.describe Users::CleanupChatChannels, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:dm_channel) do
    ChatChannel.create_with_users([user, other_user])
  end
  let!(:open_channel) do
    ChatChannel.create_with_users([user, other_user], "open")
  end

  it "deletes direct chat channels" do
    described_class.call(user)

    expect(ChatChannelMembership.find_by(chat_channel: dm_channel)).to be_nil
    expect(ChatChannel.find_by(id: dm_channel.id)).to be_nil
  end

  it "does not delete open chat channels" do
    described_class.call(user)

    ccm = ChatChannelMembership.find_by(chat_channel: open_channel, user: user)
    expect(ccm).to be_nil
    expect(ChatChannel.find(open_channel.id)).to be_present
  end
end
