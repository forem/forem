require "rails_helper"

RSpec.describe AppIntegration, type: :model do
  let!(:app_integration) { create(:app_integration, platform: Device::IOS) }

  describe "operational?" do
    context "with non-forem apps" do
      it "returns false if not active in DB or credentials are unavailable" do
        inactive_app_integration = create(:app_integration, active: false)
        expect(inactive_app_integration.operational?).to be false

        app_integration_without_credentials = create(:app_integration, auth_key: nil)
        expect(app_integration_without_credentials.operational?).to be false
      end

      it "returns true if both active && credentials are available" do
        expect(app_integration.operational?).to be true
      end
    end

    context "with forem apps" do
      it "returns true/false based on the ENV variable for the forem apps" do
        forem_app_integration = AppIntegrations::FetchOrCreateBy.call(
          app_bundle: AppIntegration::FOREM_BUNDLE,
          platform: Device::IOS,
        )
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
        expect(forem_app_integration.operational?).to be true

        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return(nil)
        expect(forem_app_integration.operational?).to be false
      end
    end
  end

  describe "after an update" do
    it "recreates the Redis-backed Rpush app" do
      rpush_app = AppIntegrations::FetchRpushApp.call(
        app_bundle: app_integration.app_bundle,
        platform: app_integration.platform,
      )
      auth_key = rpush_app.certificate

      # The Redis-backed Rpush App has the AppIntegration's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(auth_key).to eq(app_integration.auth_credentials)

      app_integration.auth_key = "new_auth_key"
      expect(app_integration.save).to be true

      # After update fetch again
      rpush_app = AppIntegrations::FetchRpushApp.call(
        app_bundle: app_integration.app_bundle,
        platform: app_integration.platform,
      )

      # The Redis-backed Rpush App has the new AppIntegration's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.certificate).to eq("new_auth_key")
    end
  end
end
