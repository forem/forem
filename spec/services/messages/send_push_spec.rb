require "rails_helper"

RSpec.describe Messages::SendPush do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:chat_channel) { create(:chat_channel) }
  let!(:message) { build(:message, chat_channel_id: chat_channel.id, user_id: user2.id) }

  before do
    create(:chat_channel_membership, user_id: user2.id, chat_channel_id: chat_channel.id)
    PushNotificationSubscription.create(
      user_id: user2.id,
      endpoint: "http://nowhere.togo", p256dh_key: "BBoN_OkTfE_0uObue",
      auth_key: "aW1hcm    thcmF",
      notification_type: "browser"
    )
    allow(Webpush).to receive(:payload_send).and_return(true)
  end

  context "when push is needed" do
    it "pushes notification subscription messages" do
      described_class.call(user1, chat_channel, message.message_html)
      expect(Webpush).to have_received(:payload_send)
    end
  end

  context "when push is not necessary" do
    before do
      membership = PushNotificationSubscription.last.user.chat_channel_memberships.order("last_opened_at DESC").first
      membership.update(last_opened_at: 3.seconds.ago)
    end

    it "does not push subscription message" do
      described_class.call(user1, chat_channel, message.message_html)
      expect(Webpush).not_to have_received(:payload_send)
    end
  end
end
