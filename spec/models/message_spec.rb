require "rails_helper"

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }
  let(:user2) { create(:user) }
  let(:long_text) { Faker::Hipster.words(1500) }

  describe "validations" do
    subject { build(:message, :ignore_after_callback) }

    before do
      allow(ChatChannel).to receive(:find).and_return(ChatChannel.new)
    end

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

  it "creates rich link in connect with proper link" do
    article = create(:article)
    message = create(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                               message_markdown: "hello http://#{ApplicationConfig['APP_DOMAIN']}#{article.path}")
    expect(message.message_html).to include(article.title)
    expect(message.message_html).to include("data-content")
  end

  it "creates rich link in connect with non-rich link" do
    message = create(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                               message_markdown: "hello http://#{ApplicationConfig['APP_DOMAIN']}/report-abuse")
    expect(message.message_html).not_to include("data-content")
  end

  it "sends email if user not recently active on /connect" do
    chat_channel.add_users([user, user2])
    chat_channel.update_column(:channel_type, "direct")
    user2.update_column(:updated_at, 1.day.ago)
    user2.chat_channel_memberships.last.update_column(:last_opened_at, 2.days.ago)
    create(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                     message_markdown: "hello http://#{ApplicationConfig['APP_DOMAIN']}/report-abuse")
    expect(EmailMessage.last.subject).to start_with("#{user.name} just messaged you")
  end

  it "does not send email if user has been recently active" do
    chat_channel.add_users([user, user2])
    create(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                     message_markdown: "hello http://#{ApplicationConfig['APP_DOMAIN']}/report-abuse")
    expect(EmailMessage.all.size).to eq(0)
  end

  it "does not send email if user has email_messages turned off" do
    chat_channel.add_users([user, user2])
    chat_channel.update_column(:channel_type, "direct")
    user2.update_column(:updated_at, 1.day.ago)
    user2.update_column(:email_connect_messages, false)
    user2.chat_channel_memberships.last.update_column(:last_opened_at, 2.days.ago)
    create(:message, chat_channel_id: chat_channel.id, user_id: user.id,
                     message_markdown: "hello http://#{ApplicationConfig['APP_DOMAIN']}/report-abuse")
    expect(EmailMessage.all.size).to eq(0)
  end
end
