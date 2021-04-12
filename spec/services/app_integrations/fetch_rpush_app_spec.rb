require "rails_helper"

RSpec.describe AppIntegrations::FetchRpushApp, type: :service do
  let(:app_integration) do
    AppIntegrations::FetchBy.call(app_bundle: AppIntegration::FOREM_BUNDLE, platform: Device::IOS)
  end

  describe "Redis-backed rpush app" do
    it "is recreated after updating a AppIntegration" do
      # Fetch rpush app associated to the target
      rpush_app = described_class.call(
        app_bundle: app_integration.app_bundle,
        platform: app_integration.platform,
      )

      expect(rpush_app).to be_instance_of(Rpush::Apns2::App)
      expect(rpush_app.name).to eq(app_integration.app_bundle)
    end
  end
end
