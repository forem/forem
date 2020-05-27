require "rails_helper"

RSpec.describe VerificationMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#account_ownership_verification_email" do
    xit "works correctly" do
      params = { user_id: user.id }
      email = described_class.account_ownership_verification_email(params)

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([SiteConfig.email_addresses[:default]])
      expect(email["from"].value).to eq("#{ApplicationConfig['COMMUNITY_NAME']} Email Verification <#{SiteConfig.email_addresses[:default]}>")
    end
  end
end
