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
        expect(email.body.to_s).to include("/users/confirmation?confirmation_token=faketoken")
      end
    end

    context "when it's a user" do
      let(:email) { described_class.confirmation_instructions(user, "faketoken") }

      it "renders the correct body" do
        expect(email.to_s).to include("You can confirm your account email through the link below:")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("/users/confirmation?confirmation_token=faketoken")
      end
    end
  end
end
