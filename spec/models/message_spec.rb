require "rails_helper"

RSpec.describe Message, type: :model do

  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel)}

  describe "validations" do
    subject { build(:message, :ignore_after_callback)}

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:chat_channel) }
    it { is_expected.to validate_presence_of(:message_html) }
    it { is_expected.to validate_presence_of(:message_markdown) }
  end

  it "is invalid without channel permission for non-open channels" do
    user_2 = create(:user)
    chat_channel.channel_type = "invite_only"
    chat_channel.save
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user_2.id)
    expect(message).not_to be_valid
    chat_channel.add_users([user_2])
    message = build(:message, chat_channel_id: chat_channel.id, user_id: user_2.id)
    expect(message).to be_valid
  end
end
