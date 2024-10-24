# spec/mailers/custom_mailer_spec.rb

require "rails_helper"

RSpec.describe CustomMailer, type: :mailer do
  describe "#custom_email" do
    let(:user) { create(:user) }
    let(:content) { "Hello, this is a test email." }
    let(:subject) { "Test Email Subject" }
    let(:unsubscribe_token) { "unsubscribe_token" }
    let(:mail) { described_class.with(user: user, content: content, subject: subject).custom_email }

    before do
      allow_any_instance_of(CustomMailer).to receive(:generate_unsubscribe_token).and_return(unsubscribe_token)
      allow_any_instance_of(CustomMailer).to receive(:email_from).and_return("no-reply@example.com")
      allow(I18n).to receive(:t).with("mailers.digest_mailer.from").and_return("From Name")
    end

    context "when SendGrid is enabled" do
      before do
        allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
      end

      it "sets the X-SMTPAPI header with the correct category" do
        expect(mail.headers["X-SMTPAPI"]).to eq({ category: "Newsletter Email" }.to_json)
      end

      it "sends the email with the correct details" do
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq(subject)
        expect(mail.from).to eq(["no-reply@example.com"])
        expect(mail.body.encoded).to include(content)
        expect(mail.body.encoded).to include(unsubscribe_token)
      end
    end

    context "when SendGrid is disabled" do
      before do
        allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(false)
      end

      it "does not set the X-SMTPAPI header" do
        expect(mail.headers["X-SMTPAPI"]).to be_nil
      end

      it "sends the email with the correct details" do
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq(subject)
        expect(mail.from).to eq(["no-reply@example.com"])
        expect(mail.body.encoded).to include(content)
        expect(mail.body.encoded).to include(unsubscribe_token)
      end
    end
  end
end
