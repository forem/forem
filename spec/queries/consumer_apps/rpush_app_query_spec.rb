require "rails_helper"

RSpec.describe ConsumerApps::RpushAppQuery, type: :query do
  let(:ios_consumer_app) do
    ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
  end
  let(:android_consumer_app) do
    ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :android)
  end

  describe "Rpush app" do
    it "is recreated after updating a ConsumerApp" do
      mock_rpush(ios_consumer_app)

      # Fetch rpush app associated to the target
      rpush_app = described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)

      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.name).to eq(ios_consumer_app.app_bundle)
    end

    it "returns nil if ConsumerApp is not operational" do
      bad_consumer_app = create(:consumer_app, auth_key: nil)

      mock_rpush(bad_consumer_app, empty: true)

      rpush_app = described_class.call(app_bundle: bad_consumer_app.app_bundle, platform: bad_consumer_app.platform)

      expect(bad_consumer_app.operational?).to be false
      expect(rpush_app).to be_nil
    end

    it "works when ConsumerApps have the same bundle but different platform" do
      # This is a regression test to avoid conflicting `name` in either
      # Rpush::Apns2::App or Rpush::Gcm::App to break the app
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("asdf123")
      allow(ApplicationConfig).to receive(:[]).with("RPUSH_FCM_KEY").and_return("asdf123")

      mock_rpush(ios_consumer_app)
      mock_rpush(android_consumer_app)

      # Fetch rpush app associated to the target
      ios_rpush_app = described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)
      expect(ios_rpush_app).to be_instance_of(Rpush::Apns2::App)

      # Fetch rpush app associated to the target
      android_rpush_app = described_class.call(app_bundle: android_consumer_app.app_bundle, platform: :android)
      expect(android_rpush_app).to be_instance_of(Rpush::Gcm::App)
    end
  end
end
