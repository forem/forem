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

    context "with subforem-specific branding" do
      let!(:subforem) { create(:subforem, domain: "custom.example.com") }
      let(:subforem_community_name) { "Custom Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
        allow(ForemInstance).to receive(:from_email_address).and_return(from_email_address)
      end

      it "uses subforem's community name in subject and from" do
        email = described_class.with(user_id: user_with_subforem.id).account_ownership_verification_email

        expect(email.subject).to include(subforem_community_name)
        expect(email["from"].value).to include(subforem_community_name)
      end

      it "uses subforem's domain in verification link" do
        email = described_class.with(user_id: user_with_subforem.id).account_ownership_verification_email

        expect(email.body.encoded).to include(subforem.domain)
      end
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

    context "with subforem-specific branding" do
      let!(:subforem) { create(:subforem, domain: "magic.example.com") }
      let(:subforem_community_name) { "Magic Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }

      before do
        user_with_subforem.update_columns(sign_in_token: "valid_token", sign_in_token_sent_at: Time.current)
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
        allow(ForemInstance).to receive(:from_email_address).and_return(from_email_address)
        allow(ForemInstance).to receive(:reply_to_email_address).and_return(reply_to_email_address)
      end

      it "uses subforem's community name in subject" do
        email = described_class.with(user_id: user_with_subforem.id).magic_link

        expect(email.subject).to eq("Sign in to #{subforem_community_name} with a magic code")
      end

      it "uses subforem's community name in from address" do
        email = described_class.with(user_id: user_with_subforem.id).magic_link

        expect(email["from"].value).to include(subforem_community_name)
      end

      it "includes subforem's domain in body" do
        email = described_class.with(user_id: user_with_subforem.id).magic_link

        expect(email.body.encoded).to include(subforem_community_name)
        expect(email.body.encoded).to include(subforem.domain)
      end

      it "uses subforem's domain in magic link URL" do
        email = described_class.with(user_id: user_with_subforem.id).magic_link

        expect(email.body.encoded).to include("#{subforem.domain}")
        expect(email.body.encoded).to include("valid_token")
      end
    end

    context "with nil onboarding_subforem_id" do
      let!(:default_subforem) { create(:subforem, domain: "default.example.com") }
      let(:default_community_name) { "Default Community" }
      let(:user_without_subforem) { create(:user, onboarding_subforem_id: nil) }

      before do
        user_without_subforem.update_columns(sign_in_token: "test_token", sign_in_token_sent_at: Time.current)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ default_subforem.id => default_subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: default_subforem.id).and_return(default_community_name)
        allow(ForemInstance).to receive(:from_email_address).and_return(from_email_address)
        allow(ForemInstance).to receive(:reply_to_email_address).and_return(reply_to_email_address)
      end

      it "falls back to default subforem's community name" do
        email = described_class.with(user_id: user_without_subforem.id).magic_link

        expect(email.subject).to include(default_community_name)
      end

      it "falls back to default subforem's domain" do
        email = described_class.with(user_id: user_without_subforem.id).magic_link

        expect(email.body.encoded).to include(default_subforem.domain)
      end
    end
  end
end
