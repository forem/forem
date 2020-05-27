require "rails_helper"

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:tag) { create(:tag) }
  let(:chat_channel) { create(:chat_channel) }
  let(:message) { create(:message, user: user) }
  let(:random_word) { Faker::Lorem.word }

  describe "validations" do
    context "with automatic validations" do
      before do
        allow(ChatChannel).to receive(:find).and_return(ChatChannel.new)
      end

      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:chat_channel) }
      it { is_expected.to validate_presence_of(:message_html) }
      it { is_expected.to validate_presence_of(:message_markdown) }
    end

    xit "is invalid without channel permission for invite only channels" do
      chat_channel.update(channel_type: "invite_only")
      message = build(:message, chat_channel: chat_channel, user: user)
      expect(message).not_to be_valid
    end

    xit "is valid with channel permission" do
      chat_channel.add_users([user])
      message = build(:message, chat_channel: chat_channel, user: user)
      expect(message).to be_valid
    end

    xit "is invalid with text over 1024 chars" do
      message = build(:message, chat_channel: chat_channel, user: user, message_markdown: "x" * 1025)
      expect(message).not_to be_valid
    end
  end

  context "when callbacks are triggered before validation" do
    let_it_be(:article) { create(:article) }

    describe "#message_html" do
      xit "creates rich link with proper link for article" do
        message.message_markdown = "hello http://#{ApplicationConfig['APP_DOMAIN']}#{article.path}"
        message.validate!

        expect(message.message_html).to include(article.title)
        expect(message.message_html).to include("sidecar-article")
      end

      xit "creates target blank link" do
        message.message_markdown = "hello http://#{ApplicationConfig['APP_DOMAIN']}#{user.path}"
        message.validate!

        expect(message.message_html).to include("<a target=\"_blank\"")
      end

      xit "creates rich link with proper link for user" do
        message.message_markdown = "hello http://#{ApplicationConfig['APP_DOMAIN']}#{user.path}"
        message.validate!

        expect(message.message_html).to include(user.name)
        expect(message.message_html).to include("sidecar-user")
      end

      xit "creates rich call link" do
        message.message_markdown = "/call"
        message.validate!

        expect(message.message_html).to include("sidecar-video")
      end

      xit "creates rich embeddable link" do
        message.message_markdown = "https://docs.google.com/ https://www.figma.com/file/"
        message.validate!

        expect(message.message_html).to include("chatchannels__richlink--base")
      end

      xit "creates rich link with proper link for tag" do
        message.message_markdown = "hello http://#{ApplicationConfig['APP_DOMAIN']}/t/#{tag.name}"
        message.validate!

        expect(message.message_html).to include(tag.name)
        expect(message.message_html).to include("sidecar-tag")
      end

      xit "creates rich link with non-rich link" do
        message.message_markdown = "hello http://#{ApplicationConfig['APP_DOMAIN']}/report-abuse"
        message.validate!

        expect(message.message_html).not_to include("data-content")
      end

      xit "creates mention if user exists" do
        message.message_markdown = "Hello @#{user.username}"
        message.validate!

        expect(message.message_html).to include "<a"
        expect(message.message_html).to include("/#{user.username}")
      end

      xit "doesn't creates mention if user exists" do
        message.message_markdown = "Hello @#{random_word}"
        message.validate!

        expect(message.message_html).not_to include "<a"
        expect(message.message_html).not_to include("/#{random_word}")
      end
    end
  end

  context "when callbacks are triggered after create" do
    before do
      chat_channel.add_users([user, user2])
    end

    xit "sends email if user not recently active on /connect" do
      chat_channel.update_column(:channel_type, "direct")
      user2.update_column(:updated_at, 1.day.ago)
      user2.chat_channel_memberships.last.update_column(:last_opened_at, 2.days.ago)

      create(:message, chat_channel: chat_channel, user: user)

      expect(EmailMessage.last.subject).to start_with("#{user.name} just messaged you")
    end

    xit "does not send email if user has been recently active" do
      expect do
        create(:message, chat_channel: chat_channel, user: user)
      end.to change(EmailMessage, :count).by(0)
    end

    xit "does not send email if user has email_messages turned off" do
      chat_channel.update_column(:channel_type, "direct")
      user2.update_columns(updated_at: 1.day.ago, email_connect_messages: false)
      user2.chat_channel_memberships.last.update_column(:last_opened_at, 2.days.ago)

      expect do
        create(:message, chat_channel: chat_channel, user: user)
      end.to change(EmailMessage, :count).by(0)
    end
  end
end
