require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:email) { VerificationMailer.with(user_id: user.id).account_ownership_verification_email }

  describe "#set_perform_deliveries" do
    it "changes perform_deliveries from true to false if smtp is not enabled" do
      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(true).to(false)
    end

    it "changes perform_deliveries from false to true if smtp is enabled" do
      described_class.perform_deliveries = false
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)

      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(false).to(true)
    end
  end

  describe "#set_delivery_options" do
    after do
      Settings::SMTP.clear_cache
    end

    it "sets proper SMTP credential during callback" do
      Settings::SMTP.user_name = Faker::Internet.username
      Settings::SMTP.password = Faker::Internet.password
      email.deliver_now

      expect(described_class.deliveries.last.delivery_method.settings).to eq(Settings::SMTP.settings)
    end
  end
end
