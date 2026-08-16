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
    end

    # A mailer that belongs to an event-triggered campaign names the event
    # instead of a transactional message. Choosing Customer.io over SMTP and
    # choosing an event over a transactional send are two separate decisions, so
    # they are two separate flags.
    describe "Track-event switching" do
      let(:event_options) do
        { customerio_event_name: "dev_digest_ready", message_data: { "a" => 1 } }
      end

      before do
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_SITE_ID").and_return("site")
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_TRACK_API_KEY").and_return("track-key")
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG) }

      it "routes to the event delivery method when the track flag is enabled for the recipient" do
        FeatureFlag.enable(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG, FeatureFlag::Actor[user])

        message = built_message(to: user.email, customerio_options: event_options)

        expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIoEvent)
        expect(message.delivery_method.settings[:customerio_event_name]).to eq("dev_digest_ready")
        expect(message.delivery_method.settings[:identifiers]).to eq(email: user.email)
        expect(message.perform_deliveries).to be(true)
      end

      # The whole design rests on this: Rails keeps owning who/what/when
      # because AhoyEmail::Observer writes its row after any delivery method
      # returns, so send counts and the digest's suppression gate survive
      # handing rendering to a campaign.
      it "still records Ahoy delivery tracking (EmailMessage) on the event path" do
        FeatureFlag.enable(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG, FeatureFlag::Actor[user])
        track_client = instance_double(Customerio::Client, batch: nil)
        stub_const("CUSTOMERIO_TRACK_API", track_client)

        expect do
          DeliverableTestMailer.with(to: user.email, customerio_options: event_options).test_email.deliver_now
        end.to change(EmailMessage, :count).by(1)

        expect(track_client).to have_received(:batch)
      end

      it "keeps a mailer that names no event on the transactional path" do
        FeatureFlag.enable(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG, FeatureFlag::Actor[user])

        message = built_message(
          to: user.email,
          customerio_options: { transactional_message_id: "dev_test" },
        )

        expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      end

      it "falls back to the transactional path when the track flag is off for the recipient" do
        FeatureFlag.enable(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG, FeatureFlag::Actor[create(:user)])

        message = built_message(to: user.email, customerio_options: event_options)

        expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      end

      # DeliveryMethods::CustomerIo merges its settings straight into the
      # send_email payload; the App API defines no such field, so the request
      # must not carry it to Customer.io.
      it "keeps customerio_event_name out of the transactional send_email payload" do
        api_client = instance_double(Customerio::APIClient, send_email: { "delivery_id" => "x" })
        stub_const("CUSTOMERIO_API", api_client)

        DeliverableTestMailer.with(to: user.email, customerio_options: event_options).test_email.deliver_now

        request = nil
        expect(api_client).to have_received(:send_email) { |req| request = req }
        expect(request.message).not_to have_key(:customerio_event_name)
      end

      # The flag can be enabled before the credentials are deployed; that must
      # degrade to the transactional path rather than to a client with no auth.
      it "stays on the transactional path when the Track API is not configured" do
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_TRACK_API_KEY").and_return(nil)
        FeatureFlag.enable(Deliverable::CUSTOMERIO_TRACK_EVENT_FLAG, FeatureFlag::Actor[user])

        message = built_message(to: user.email, customerio_options: event_options)

        expect(message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      end
    end

    describe "layout message data" do
      before do
        stub_const("DeliverableLayoutTestMailer", Class.new(ApplicationMailer) do
          def test_email
            @user = params[:user]
            customerio_delivery_options(
              transactional_message_id: "dev_test",
              message_data: params[:message_data] || {},
            )
            # rubocop:disable Rails/I18nLocaleTexts -- filler content for a test-only mailer, not user-facing copy
            mail(to: @user.email, subject: "Test subject", body: "Test body")
            # rubocop:enable Rails/I18nLocaleTexts
          end
        end)
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      def layout_data(message_data: nil)
        DeliverableLayoutTestMailer
          .with(user: user, message_data: message_data)
          .test_email.message.delivery_method.settings[:message_data]
      end

      it "supplies the greeting and footer keys that the Customer.io layout renders" do
        data = layout_data

        expect(data["name"]).to eq(user.name)
        expect(data["signed_up_with_html"]).to include("magic link")
        expect(data["notification_settings_url"]).to include("/settings")
      end

      it "lets a mailer's own message_data win over the layout defaults" do
        expect(layout_data(message_data: { "name" => "Override" })["name"]).to eq("Override")
      end

      it "omits layout data when the mailer does not set @user" do
        settings = built_message(
          to: user.email,
          customerio_options: { transactional_message_id: "dev_test", message_data: { "a" => 1 } },
        ).delivery_method.settings

        expect(settings[:message_data]).to eq("a" => 1)
      end

      # DeviseMailer descends from Devise::Mailer, so it renders without
      # layouts/mailer.html.erb and without AuthenticationHelper -- its security
      # emails have never carried this footer. Note Devise's
      # initialize_from_record still sets @user, so the ivar alone is not a
      # reliable signal for the guard.
      it "omits layout data for DeviseMailer" do
        message = DeviseMailer.reset_password_instructions(user, "token").message

        expect(message.delivery_method.settings[:message_data].keys)
          .not_to include("signed_up_with_html")
      end

      it "omits the footer on magic_link, matching layouts/mailer.html.erb" do
        user.update_columns(sign_in_token: "12345678", sign_in_token_sent_at: Time.current)

        message = VerificationMailer.with(user_id: user.id).magic_link.message

        expect(message.delivery_method.settings[:message_data].keys)
          .not_to include("signed_up_with_html")
      end
    end
  end
end
