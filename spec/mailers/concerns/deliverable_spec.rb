require "rails_helper"

RSpec.describe Deliverable do
  before do
    stub_const("DeliverableTestMailer", Class.new(ApplicationMailer) do
      def test_email
        customerio_delivery_options(params[:customerio_options]) if params[:customerio_options]
        # rubocop:disable Rails/I18nLocaleTexts -- filler content for a test-only mailer, not user-facing copy
        mail(to: params[:to], subject: "Test subject", body: "Test body")
        # rubocop:enable Rails/I18nLocaleTexts
      end
    end)
  end

  def built_message(to:, customerio_options: nil)
    DeliverableTestMailer.with(to: to, customerio_options: customerio_options).test_email.message
  end

  context "when CUSTOMERIO_APP_KEY is not configured" do
    it "merges SMTP settings into the delivery method, exactly as before" do
      message = built_message(to: "anyone@example.com")
      expect(message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
      expect(message.delivery_method.settings).to include(Settings::SMTP.settings)
    end

    it "records a nil cio_delivery_id on the EmailMessage row for SMTP-mode deliveries" do
      expect do
        DeliverableTestMailer.with(to: "anyone@example.com").test_email.deliver_now
      end.to change(EmailMessage, :count).by(1)

      expect(EmailMessage.last.cio_delivery_id).to be_nil
    end
  end

  context "when CUSTOMERIO_APP_KEY is configured" do
    let(:user) { create(:user) }

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
    end

    after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

    it "routes through Customer.io when the flag is enabled for the recipient user" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])

      message = built_message(to: user.email)

      expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      expect(message.delivery_method.settings[:identifiers]).to eq(email: user.email)
      expect(message.perform_deliveries).to be(true)
    end

    it "identifies the recipient by MLH Core uid when an mlh identity exists" do
      # The :identity factory's auth_data_dump reads OmniAuth.config.mock_auth,
      # which has no built-in :mlh payload; register one (as other mlh-identity
      # specs do) so the factory doesn't raise KeyError.
      omniauth_mock_mlh_payload
      create(:identity, provider: "mlh", user: user, uid: "core-99")
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])

      message = built_message(to: user.email)

      expect(message.delivery_method.settings[:identifiers]).to eq(id: "core-99")
    end

    it "passes customerio_delivery_options through to the delivery method" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])

      message = built_message(
        to: user.email,
        customerio_options: { transactional_message_id: "dev_test", message_data: { "a" => 1 } },
      )

      expect(message.delivery_method.settings[:transactional_message_id]).to eq("dev_test")
      expect(message.delivery_method.settings[:message_data]).to eq("a" => 1)
    end

    it "falls back to SMTP when the flag is not enabled for the recipient" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[create(:user)])

      message = built_message(to: user.email)

      expect(message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
      expect(message.delivery_method.settings).to include(Settings::SMTP.settings)
    end

    it "uses the flag's global gate for recipients who are not users" do
      message = built_message(to: "stranger@example.com")
      expect(message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)

      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG)
      message = built_message(to: "stranger@example.com")
      expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      expect(message.delivery_method.settings[:identifiers]).to eq(email: "stranger@example.com")
    end

    it "matches the recipient user case-insensitively" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])

      message = built_message(to: user.email.upcase)

      expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
    end

    it "still records Ahoy delivery tracking (EmailMessage) when routed through Customer.io" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      api_client = instance_double(Customerio::APIClient, send_email: { "delivery_id" => "x" })
      stub_const("CUSTOMERIO_API", api_client)

      expect do
        DeliverableTestMailer.with(to: user.email).test_email.deliver_now
      end.to change(EmailMessage, :count).by(1)

      expect(api_client).to have_received(:send_email)
      expect(EmailMessage.last.cio_delivery_id).to eq("x")
    end

    it "records a nil cio_delivery_id when the Customer.io response omits a delivery_id" do
      FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      api_client = instance_double(Customerio::APIClient, send_email: { "meta" => {} })
      stub_const("CUSTOMERIO_API", api_client)

      expect do
        DeliverableTestMailer.with(to: user.email).test_email.deliver_now
      end.to change(EmailMessage, :count).by(1)

      expect(EmailMessage.last.cio_delivery_id).to be_nil
    end
  end
end
