require "rails_helper"

RSpec.describe DeviseMailer do
  let(:user) { create(:user) }

  describe "#reset_password_instructions" do
    let(:email) { described_class.reset_password_instructions(user, "test") }
    let(:from_email_address) { "custom_noreply@forem.com" }
    let(:reply_to_email_address) { "custom_reply@forem.com" }

    before do
      allow(Settings::General).to receive(:app_domain).and_return("funky-one-of-a-kind-domain-#{rand(100)}.com")
      allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
      allow(Settings::SMTP).to receive(:reply_to_email_address).and_return(reply_to_email_address)
    end

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
        expect(email.body.to_s).to include("confirmation_token%3Dfaketoken") # encoded URL
      end
    end

    context "when it's a user" do
      let(:email) { described_class.confirmation_instructions(user, "faketoken") }

      it "renders the correct body" do
        expect(email.to_s).to include("You can confirm your account email through the link below:")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("confirmation_token%3Dfaketoken")
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

    before do
      allow(Settings::SMTP).to receive_messages(
        from_email_address: "custom_noreply@example.com",
        reply_to_email_address: "custom_reply@example.com",
      )
    end

    it "uses the custom invite subject if provided" do
      expect(email.subject).to eq(custom_invite_subject)
    end

    it "falls back to default subject if custom subject is not provided" do
      email_without_custom_subject = described_class.invitation_instructions(user, token, {})
      expect(email_without_custom_subject.subject).to eq("Invitation Instructions")
    end

    it "includes the custom invite message if provided" do
      # Ensure your email view actually includes @message
      expect(email.to_s).to include(custom_invite_message)
    end

    it "does not include overridden default message if invite message is provided" do
      # Ensure your email view actually includes @message
      expect(email.to_s).not_to include("<p>#{I18n.t('devise.mailer.invitation_instructions.accept_instructions')}")
    end

    it "includes the custom invite footnote if provided" do
      # Ensure your email view actually includes @footnote
      expect(email.to_s).to include(custom_invite_footnote)
    end
  end
end
