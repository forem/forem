require "rails_helper"

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }
  let(:user2) { create(:user) }
  let(:long_text) { Faker::Hipster.words(1500) }

  describe "validations" do
    subject { build(:message, :ignore_after_callback) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:chat_channel) }
    it { is_expected.to validate_presence_of(:message_html) }
    it { is_expected.to validate_presence_of(:message_markdown) }
  end

  it "is invalid without channel permission for non-open channels" do
    chat_channel.update(channel_type: "invite_only")
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user2.id)
    expect(message).not_to be_valid
  end

  it "is valid with channel permission" do
    chat_channel.add_users([user2])
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user2.id)
    expect(message).to be_valid
  end

  it "is invalid if over 1024 chars" do
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                              message_markdown: long_text)
    expect(message).not_to be_valid
  end

  it "is valid if under 1024 chars" do
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                              message_markdown: "hello")
    expect(message).to be_valid
  end
end
