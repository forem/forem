require "rails_helper"

RSpec.describe ConsumerApp, type: :model do
  let!(:consumer_app_android) { create(:consumer_app, platform: Device::ANDROID) }
  let!(:consumer_app_ios) { create(:consumer_app, platform: Device::IOS) }

  describe "operational?" do
    context "with non-Forem apps" do
      it "returns false if not active in DB or if credentials are unavailable" do
        inactive_consumer_app = create(:consumer_app, active: false)
        expect(inactive_consumer_app.operational?).to be(false)

        consumer_app_without_credentials = create(:consumer_app, auth_key: nil)
        expect(consumer_app_without_credentials.operational?).to be(false)
      end

      it "returns true if both active and credentials are available for Android" do
        expect(consumer_app_android.operational?).to be(true)
      end

      it "returns true if both active and credentials are available for iOS" do
        expect(consumer_app_ios.operational?).to be(true)
      end
    end

    context "with Forem apps" do
      it "returns true/false based on the ENV variable for the Forem apps" do
        forem_consumer_app = ConsumerApps::FindOrCreateByQuery.call(
          app_bundle: ConsumerApp::FOREM_BUNDLE,
          platform: ConsumerApp::FOREM_APP_PLATFORMS.sample,
        )
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
        expect(forem_consumer_app.operational?).to be(true)

        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return(nil)
        expect(forem_consumer_app.operational?).to be(false)
      end
    end
  end

  describe "after an update" do
    it "recreates the Rpush app for Android", :aggregate_failures do
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app_android.app_bundle,
        platform: consumer_app_android.platform,
      )

      # The Rpush App has the ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Gcm::App)
      expect(rpush_app.auth_key).to eq(consumer_app_android.auth_credentials)

      consumer_app_android.auth_key = "new_auth_key"
      expect(consumer_app_android.save).to be(true)

      # After update fetch again
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app_android.app_bundle,
        platform: consumer_app_android.platform,
      )

      # The Rpush App has the new ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Gcm::App)
      expect(rpush_app.auth_key).to eq("new_auth_key")
    end

    it "recreates the Rpush app for iOS", :aggregate_failures do
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app_ios.app_bundle,
        platform: consumer_app_ios.platform,
      )

      # The Rpush App has the ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.certificate).to eq(consumer_app_ios.auth_credentials)

      consumer_app_ios.auth_key = "new_auth_key"
      expect(consumer_app_ios.save).to be(true)

      # After update fetch again
      rpush_app = ConsumerApps::RpushAppQuery.call(
        app_bundle: consumer_app_ios.app_bundle,
        platform: consumer_app_ios.platform,
      )

      # The Rpush App has the new ConsumerApp's auth_credentials
      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.certificate).to eq("new_auth_key")
    end
  end
end
