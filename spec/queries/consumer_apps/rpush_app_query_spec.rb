require "rails_helper"

RSpec.describe ConsumerApps::RpushAppQuery, type: :query do
  let!(:ios_consumer_app) do
    ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
  end
  let!(:android_consumer_app) do
    ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :android)
  end

  describe "Rpush app" do
    it "returns nil if ConsumerApp is not operational" do
      bad_consumer_app = create(:consumer_app, auth_key: nil)

      mock_rpush(bad_consumer_app, empty: true)

      rpush_app = described_class.call(app_bundle: bad_consumer_app.app_bundle, platform: bad_consumer_app.platform)

      expect(bad_consumer_app.operational?).to be false
      expect(rpush_app).to be_nil
    end

    it "returns the proper app when ConsumerApps have the same bundle but different platform" do
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

    # rubocop:disable RSpec/AnyInstance
    context "when querying iOS rpush app" do
      before do
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("onetwothree")
        mock_rpush(ios_consumer_app)
      end

      it "forces to recreate (iOS rpush app) when ENV var changes" do
        # Fetch rpush app associated to the target
        rpush_app = described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)
        expect(rpush_app).to be_instance_of(Rpush::Apns2::App)

        # Update ENV var & stub rpush_app check it was destroyed + recreated
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_IOS_PEM").and_return("fourfivesix")
        allow(rpush_app).to receive(:destroy)
        allow_any_instance_of(described_class).to receive(:recreate_ios_app!)

        # Fetch rpush app again
        described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)
        expect(rpush_app).to have_received(:destroy).once
      end

      it "doesn't recreate (iOS rpush app) when ENV var doesn't change" do
        # Fetch rpush app associated to the target
        rpush_app = described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)
        expect(rpush_app).to be_instance_of(Rpush::Apns2::App)

        # ENV var hasn't changed & stub rpush_app check it wasn't destroyed + recreated
        allow(rpush_app).to receive(:destroy)
        allow_any_instance_of(described_class).to receive(:recreate_ios_app!)

        # Fetch rpush app again
        described_class.call(app_bundle: ios_consumer_app.app_bundle, platform: :ios)
        expect(rpush_app).not_to have_received(:destroy)
      end
    end

    context "when querying Android rpush app" do
      before do
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_FCM_KEY").and_return("onetwothree")
        mock_rpush(android_consumer_app)
      end

      it "forces to recreate (Android rpush app) when ENV var changes" do
        # Fetch rpush app associated to the target
        rpush_app = described_class.call(app_bundle: android_consumer_app.app_bundle, platform: :android)
        expect(rpush_app).to be_instance_of(Rpush::Gcm::App)

        # Update ENV var & stub rpush_app check it was destroyed + recreated
        allow(ApplicationConfig).to receive(:[]).with("RPUSH_FCM_KEY").and_return("fourfivesix")
        allow(rpush_app).to receive(:destroy)
        allow_any_instance_of(described_class).to receive(:recreate_android_app!)

        # Fetch rpush app again
        described_class.call(app_bundle: android_consumer_app.app_bundle, platform: :android)
        expect(rpush_app).to have_received(:destroy).once
      end

      it "doesn't recreate (Android rpush app) when ENV var doesn't change" do
        # Fetch rpush app associated to the target
        rpush_app = described_class.call(app_bundle: android_consumer_app.app_bundle, platform: :android)
        expect(rpush_app).to be_instance_of(Rpush::Gcm::App)

        # ENV var hasn't changed & stub rpush_app check it wasn't destroyed + recreated
        allow(rpush_app).to receive(:destroy)
        allow_any_instance_of(described_class).to receive(:recreate_android_app!)

        # Fetch rpush app again
        described_class.call(app_bundle: android_consumer_app.app_bundle, platform: :android)
        expect(rpush_app).not_to have_received(:destroy)
      end
    end
    # rubocop:enable RSpec/AnyInstance
  end
end
