require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:email) { VerificationMailer.with(user_id: user.id).account_ownership_verification_email }

  xdescribe "#set_perform_deliveries" do
    it "changes perform_deliveries from true to false if smtp is not enabled" do
      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(true).to(false)
    end

    it "changes perform_deliveries from false to true if smtp is enabled" do
      described_class.perform_deliveries = false
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)

      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(false).to(true)
    end
  end

  xdescribe "#set_delivery_options" do
    it "evoked Settings::SMTP.settings during callback" do
      allow(Settings::SMTP).to receive(:settings)
      email.deliver_now
      expect(Settings::SMTP).to have_received(:settings)
    end
  end
end
