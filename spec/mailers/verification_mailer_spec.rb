require "rails_helper"

RSpec.describe VerificationMailer do
  let(:user) { create(:user) }
  let(:from_email_address) { "custom_noreply@forem.com" }

  describe "#account_ownership_verification_email" do
    before do
      allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
    end

    it "works correctly", :aggregate_failures do
      email = described_class.with(user_id: user.id).account_ownership_verification_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([from_email_address])
      from = "#{Settings::Community.community_name} Email Verification <#{from_email_address}>"
      expect(email["from"].value).to eq(from)
    end
  end
end
