require "rails_helper"

RSpec.describe VerificationMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#account_ownership_verification_email" do
    it "works correctly" do
      email = described_class.with(user_id: user.id).account_ownership_verification_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([ForemInstance.email])
      from = "#{Settings::Community.community_name} Email Verification <#{ForemInstance.email}>"
      expect(email["from"].value).to eq(from)
    end
  end
end
