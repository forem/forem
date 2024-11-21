require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  include Devise::Controllers::UrlHelpers  # Include Devise route helpers

  let(:user) { create(:user) }
  let(:from_email_address) { "custom_noreply@forem.com" }
  let(:reply_to_email_address) { "custom_reply@forem.com" }
  let(:community_name) { "Forem Community" }
  let(:app_domain) { "funky-one-of-a-kind-domain-#{rand(100)}.com" }

  before do
    allow(Settings::Community).to receive(:community_name).and_return(community_name)
    allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
    allow(Settings::General).to receive(:app_domain).and_return(app_domain)
    allow(ForemInstance).to receive(:from_email_address).and_return(from_email_address)
    allow(ForemInstance).to receive(:reply_to_email_address).and_return(reply_to_email_address)
    ActionMailer::Base.default_url_options[:host] = app_domain
    DeviseMailer.default_url_options[:host] = app_domain
  end

  describe "#magic_link" do
    let(:token) { 'some_token' }
    let(:email) { described_class.magic_link(user, token) }

    it "renders the correct sender email" do
      expected_from = [from_email_address]
      expect(email.from).to eq(expected_from)
    end

    it "includes the display name in the from header" do
      expected_display_from = "#{community_name} <#{from_email_address}>"
      expect(email[:from].to_s).to eq(expected_display_from)
    end

    it "renders the correct reply-to email address" do
      expect(email.reply_to).to eq([reply_to_email_address])
    end

    it "sends the email to the user's email address" do
      expect(email.to).to eq([user.email])
    end

    it "renders the correct subject" do
      expected_subject = "Log in to #{community_name} with a magic link"
      expect(email.subject).to eq(expected_subject)
    end

    xit "includes the magic link URL in the email body" do
      expected_url = magic_link_url(user, email: user.email, token: token, remember_me: true)
      expect(email.body.encoded).to include(expected_url)
    end

    it "includes the token in the email body" do
      expect(email.body.encoded).to include("token=#{token}")
    end
  end

  describe "#reset_password_instructions" do
    let(:email) { described_class.reset_password_instructions(user, "test") }

    it "renders sender" do
      expected_from = "#{Settings::Community.community_name} <#{from_email_address}>"
      expect(email["from"].value).to eq(expected_from)
    end

    it "renders a reply to email address" do
      expect(email["reply_to"].value).to eq(reply_to_email_address)
    end

    it "renders proper URL" do
      expect(email.to_s).to include(Settings::General.app_domain)
    end
  end

  describe "#confirmation_instructions" do
    context "when it's a Forem creator" do
      let!(:creator) { create(:user, :super_admin, :creator) }
      let(:email) { described_class.confirmation_instructions(creator, "faketoken") }

      it "renders the correct body" do
        expect(email.body.to_s).to include("Hello! Once you've confirmed your email address, you'll be able to setup " \
                                           "your Forem Instance.")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("confirmation_token=faketoken") # encoded URL
      end
    end

    context "when it's a user" do
      let(:email) { described_class.confirmation_instructions(user, "faketoken") }

      it "renders the correct body" do
        expect(email.to_s).to include("You can confirm your account email through the link below:")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("confirmation_token=faketoken")
      end
    end
  end

  describe "#invitation_instructions" do
    let(:token) { "some_token" }
    let(:custom_invite_message) { "Join our community!!" }
    let(:custom_invite_footnote) { "Looking forward to seeing you!!" }
    let(:custom_invite_subject) { "You've Been Invited" }

    let(:opts) do
      {
        custom_invite_message: custom_invite_message,
        custom_invite_footnote: custom_invite_footnote,
        custom_invite_subject: custom_invite_subject
      }
    end

    let(:email) { described_class.invitation_instructions(user, token, opts) }

    it "uses the custom invite subject if provided" do
      expect(email.subject).to eq(custom_invite_subject)
    end

    it "falls back to default subject if custom subject is not provided" do
      email_without_custom_subject = described_class.invitation_instructions(user, token, {})
      expect(email_without_custom_subject.subject).to eq("Invitation Instructions")
    end

    it "includes the custom invite message if provided" do
      expect(email.body.encoded).to include(custom_invite_message)
    end

    it "does not include overridden default message if invite message is provided" do
      expect(email.body.encoded).not_to include("<p>#{I18n.t('devise.mailer.invitation_instructions.accept_instructions')}")
    end

    it "includes the custom invite footnote if provided" do
      expect(email.body.encoded).to include(custom_invite_footnote)
    end
  end
end
