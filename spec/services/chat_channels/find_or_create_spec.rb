require "rails_helper"

RSpec.describe ChatChannels::FindOrCreate, type: :service do
  let(:users) { create_list(:user, 2) }
  let(:usernames) { users.map(&:username).sort }
  let(:direct_slug) { usernames.join("/") }
  let(:other_slug) { "New Channel-#{rand(100_000).to_s(26)}" }
  let(:contrived_name) { "Direct chat between #{usernames.join(' and ')}" }
  let(:open_slug) { "Test channel-#{rand(100_000).to_s(26)}" }
  let(:chat_channel) do
    ChatChannel.create(
      channel_type: "open",
      channel_name: "Open chat channel for test",
      slug: open_slug,
      last_message_at: 1.week.ago,
      status: "active",
    )
  end

  describe "#call find a chat channel" do
    it "did not find a channel" do
      new_chat_channel = described_class.call("direct", direct_slug, contrived_name)
      expect(new_chat_channel.direct?).to be(true)
      expect(new_chat_channel.status).to eql("active")
      expect(new_chat_channel.slug).to eql(direct_slug)
      expect(new_chat_channel.channel_name).to eql(contrived_name)
    end

    it "found a channel" do
      found_chat_channel = described_class.call("open", open_slug, "Open chat channel for test")
      expect(found_chat_channel.open?).to be(true)
      expect(found_chat_channel.slug).to eql(open_slug)
      expect(found_chat_channel.channel_name).to eql("Open chat channel for test")
      expect(found_chat_channel.last_message_at.day).to eq(chat_channel.last_message_at.day)
    end
  end
end
