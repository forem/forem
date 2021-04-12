require "rails_helper"

RSpec.describe AppIntegrations::FetchBy, type: :service do
  context "when fetching the Forem app" do
    it "recreates the record if it doesn't exist" do
      expect(AppIntegration.count).to eq(0)

      expect do
        app = described_class.call(app_bundle: AppIntegration::FOREM_BUNDLE, platform: Device::IOS)
        expect(app).to be_instance_of(AppIntegration)
      end.to change(AppIntegration, :count).by(1)
    end
  end

  context "when fetching other AppIntegrations" do
    it "returns the requested AppIntegration" do
      app_integration = create(:app_integration)
      expect do
        result = described_class.call(app_bundle: app_integration.app_bundle, platform: app_integration.platform)
        expect(result).to be_instance_of(AppIntegration)
        expect(result.id).to eq(app_integration.id)
      end.not_to change(AppIntegration, :count)
    end
  end
end
