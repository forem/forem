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

      it "includes name in welcome email" do
        email = described_class.confirmation_instructions(user, "faketoken")
        expect(email.body.to_s).to include("Welcome #{user.name}")
      end
        

      it "does not include name in confirmation email if includes http" do
        user.update!(name: "Testing https://example.com")
        email = described_class.confirmation_instructions(user, "faketoken")
        expect(email.body.to_s).not_to include("https://example.com")
        expect(email.body.to_s).to include("Welcome!")
      end
    end

    context "when user has an onboarding_subforem_id" do
      let!(:subforem) { create(:subforem, domain: "custom.example.com") }
      let!(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:subforem_community_name) { "Custom Subforem" }

      before do
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_id).and_return(1)
        allow(Subforem).to receive(:cached_default_domain).and_return("default.example.com")
      end

      let(:email) { described_class.confirmation_instructions(user_with_subforem, "faketoken") }

      it "uses the subforem's domain in the confirmation URL" do
        expect(email.body.to_s).to include(subforem.domain)
      end

      it "uses the subforem's community name in the sender" do
        expected_from = "#{subforem_community_name} <#{from_email_address}>"
        expect(email["from"].value).to eq(expected_from)
      end

      it "uses the subforem's community name in the subject" do
        expect(email.subject).to include(subforem_community_name)
      end
    end

    context "when user has no onboarding_subforem_id" do
      let!(:user_without_subforem) { create(:user, onboarding_subforem_id: nil) }
      let(:default_subforem_domain) { "default.example.com" }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(1)
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem_domain)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ 1 => default_subforem_domain })
      end

      let(:email) { described_class.confirmation_instructions(user_without_subforem, "faketoken") }

      it "falls back to the default subforem domain" do
        expect(email.body.to_s).to include(default_subforem_domain)
      end

      it "uses the default community name in the sender" do
        expected_from = "#{community_name} <#{from_email_address}>"
        expect(email["from"].value).to eq(expected_from)
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

  describe "edge cases" do
    context "when multiple users have different subforems" do
      let!(:subforem1) { create(:subforem, domain: "subforem1.example.com") }
      let!(:subforem2) { create(:subforem, domain: "subforem2.example.com") }
      let(:community_name1) { "Community One" }
      let(:community_name2) { "Community Two" }
      let(:user1) { create(:user, onboarding_subforem_id: subforem1.id) }
      let(:user2) { create(:user, onboarding_subforem_id: subforem2.id) }

      before do
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({
          subforem1.id => subforem1.domain,
          subforem2.id => subforem2.domain
        })
        allow(Subforem).to receive(:cached_default_domain).and_return("default.example.com")
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem1.id).and_return(community_name1)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem2.id).and_return(community_name2)
      end

      it "sends emails to each user with their respective subforem" do
        email1 = described_class.confirmation_instructions(user1, "token1")
        email2 = described_class.confirmation_instructions(user2, "token2")

        expect(email1.body.to_s).to include(subforem1.domain)
        expect(email2.body.to_s).to include(subforem2.domain)

        expect(email1.subject).to include(community_name1)
        expect(email2.subject).to include(community_name2)
      end
    end

    context "when user has an invalid subforem_id" do
      let(:user_with_invalid_subforem) { create(:user, onboarding_subforem_id: 999999) }
      let!(:default_subforem) { create(:subforem, domain: "default.example.com") }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ default_subforem.id => default_subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
      end

      it "falls back to default subforem" do
        email = described_class.confirmation_instructions(user_with_invalid_subforem, "token")
        expect(email.body.to_s).to include(default_subforem.domain)
      end
    end

    context "when domain already includes port number" do
      let!(:subforem) { create(:subforem, domain: "dev.example.com:3000") }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "doesn't add :3000 port twice" do
        email = described_class.confirmation_instructions(user_with_subforem, "token")
        # Should not have :3000:3000 in the body
        expect(email.body.to_s).not_to include(":3000:3000")
        expect(email.body.to_s).to include("dev.example.com:3000")
      end
    end

    context "reset_password_instructions with subforem" do
      let!(:subforem) { create(:subforem, domain: "reset.example.com") }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::General).to receive(:app_domain).and_return("fallback.example.com")
      end

      it "uses subforem domain in reset password link" do
        email = described_class.reset_password_instructions(user_with_subforem, "reset_token")
        expect(email.body.to_s).to include(subforem.domain)
      end
    end
  end
end
