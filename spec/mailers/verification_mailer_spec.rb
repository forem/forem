require "rails_helper"

RSpec.describe VerificationMailer do
  let(:user) { create(:user) }
  let(:from_email_address) { "custom_noreply@forem.com" }
  let(:reply_to_email_address) { "support@forem.com" }
  let(:community_name) { "Forem Community" }

  describe "#account_ownership_verification_email" do
    before do
      allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
      allow(Settings::Community).to receive(:community_name).and_return(community_name)
    end

    it "works correctly", :aggregate_failures do
      email = described_class.with(user_id: user.id).account_ownership_verification_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([from_email_address])
      from = "#{community_name} Email Verification <#{from_email_address}>"
      expect(email["from"].value).to eq(from)
    end
  end

  describe "#magic_link" do
    before do
      allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
      allow(Settings::SMTP).to receive(:reply_to_email_address).and_return(reply_to_email_address)
      allow(Settings::Community).to receive(:community_name).and_return(community_name)
    end

    it "sends a magic link email", :aggregate_failures do
      user.update_columns(sign_in_token: "valid_token", sign_in_token_sent_at: Time.current)
      email = described_class.with(user_id: user.id).magic_link

      expect(email.subject).to eq("Sign in to #{community_name} with a magic code")
      expect(email.to).to eq([user.email])
      expect(email.reply_to).to eq([reply_to_email_address])
    end

    it "does not include the generic magic link copy" do
      user.update_columns(sign_in_token: "valid_token", sign_in_token_sent_at: Time.current)
      email = described_class.with(user_id: user.id).magic_link

      expect(email.body.encoded).not_to include("Not signed-in on this device?")
    end
  end
end
