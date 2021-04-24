require "rails_helper"

RSpec.describe ConsumerApp, type: :model do
  let!(:consumer_app) { create(:consumer_app, platform: Device::IOS) }

  describe "operational?" do
    context "with non-forem apps" do
      it "returns false if not active in DB or credentials are unavailable" do
        inactive_consumer_app = create(:consumer_app, active: false)
        expect(inactive_consumer_app.operational?).to be false

        consumer_app_without_credentials = create(:consumer_app, auth_key: nil)
        expect(consumer_app_without_credentials.operational?).to be false
      end

      it "returns true if both active && credentials are available" do
        expect(consumer_app.operational?).to be true
      end
    end

    context "with forem apps" do
      it "returns true/false based on the ENV variable for the forem apps" do
        forem_consumer_app = ConsumerApps::FindOrCreateByQuery.call(
          app_bundle: ConsumerApp::FOREM_BUNDLE,
          platform: ConsumerApp::FOREM_APP_PLATFORMS.sample,
        )
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
        expect(forem_consumer_app.operational?).to be true

        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return(nil)
        expect(forem_consumer_app.operational?).to be false
      end
    end
  end

  describe "after an update" do
    it "recreates the Redis-backed Rpush app" do
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app.app_bundle,
        platform: consumer_app.platform,
      )
      auth_key = rpush_app.certificate

      # The Redis-backed Rpush App has the ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(auth_key).to eq(consumer_app.auth_credentials)

      consumer_app.auth_key = "new_auth_key"
      expect(consumer_app.save).to be true

      # After update fetch again
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app.app_bundle,
        platform: consumer_app.platform,
      )

      # The Redis-backed Rpush App has the new ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.certificate).to eq("new_auth_key")
    end
  end
end
