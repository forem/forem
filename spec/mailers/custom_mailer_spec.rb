require "rails_helper"

RSpec.describe CustomMailer, type: :mailer do
  describe "#custom_email" do
    let(:user) { create(:user) }
    let(:content) { "Hello *|name|*, this is a test email." }
    let(:subject) { "Test Email Subject for *|name|*" }
    let(:unsubscribe_token) { "unsubscribe_token" }
    let(:mail) { described_class.with(user: user, content: content, subject: subject).custom_email }

    before do
      allow_any_instance_of(CustomMailer).to receive(:generate_unsubscribe_token).and_return(unsubscribe_token)
      allow_any_instance_of(CustomMailer).to receive(:email_from).and_return("no-reply@example.com")
    end

    context "when SendGrid is enabled" do
      before do
        allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
      end

      it "sets the X-SMTPAPI header with the correct category" do
        mail.deliver_now

        expect(mail.header["X-SMTPAPI"]).not_to be_nil
        smtpapi_header = JSON.parse(mail.header["X-SMTPAPI"].value)
        expect(smtpapi_header).to have_key("category")
        expect(smtpapi_header["category"]).to include("Custom Email")
      end

      it "replaces the *|name|* merge tag in content and subject" do
        expected_content = "Hello #{user.name}, this is a test email."
        expected_subject = "Test Email Subject for #{user.name}"

        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq(expected_subject)
        expect(mail.from).to eq(["no-reply@example.com"])
        expect(mail.body.encoded).to include(expected_content)
        expect(mail.body.encoded).to include(unsubscribe_token)
      end
    end

    context "when there is an email passed" do
      let(:email) { create(:email, type_of: "onboarding_drip") }
      let(:second_user) { create(:user) }

      before do

        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      end

      it "tracks the email_id after delivery" do
        described_class.with(user: second_user, content: content, subject: subject, email_id: email.id).custom_email.deliver_now
        expect(email.reload.email_messages.count).to eq(1)
      end
    end

    context "when SendGrid is disabled" do
      before do
        allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(false)
      end

      it "does not set the X-SMTPAPI header" do
        expect(mail.headers["X-SMTPAPI"]).to be_nil
      end

      it "replaces the *|name|* merge tag in content and subject" do
        expected_content = "Hello #{user.name}, this is a test email."
        expected_subject = "Test Email Subject for #{user.name}"

        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq(expected_subject)
        expect(mail.from).to eq(["no-reply@example.com"])
        expect(mail.body.encoded).to include(expected_content)
        expect(mail.body.encoded).to include(unsubscribe_token)
      end
    end
  end
end
