require "rails_helper"

RSpec.describe VerificationMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:from_email_address) { "noreply@forem.com" }

  describe "#account_ownership_verification_email" do
    before do
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
    end

    it "works correctly" do
      email = described_class.with(user_id: user.id).account_ownership_verification_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([from_email_address])
      from = "#{Settings::Community.community_name} Email Verification <#{from_email_address}>"
      expect(email["from"].value).to eq(from)
    end
  end
end
