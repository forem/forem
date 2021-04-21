require "rails_helper"

RSpec.describe ConsumerApps::RpushAppQuery, type: :query do
  let(:consumer_app) do
    ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: Device::IOS)
  end

  describe "Redis-backed rpush app" do
    it "is recreated after updating a ConsumerApp" do
      # Fetch rpush app associated to the target
      rpush_app = described_class.call(
        app_bundle: consumer_app.app_bundle,
        platform: consumer_app.platform,
      )

      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.name).to eq(consumer_app.app_bundle)
    end
  end
end
