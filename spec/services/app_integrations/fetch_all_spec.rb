require "rails_helper"

RSpec.describe AppIntegrations::FetchAll, type: :service do
  let!(:app_integration) { create(:app_integration) }

  it "fetches all AppIntegrations including the Forem apps" do
    all_app_integrations = described_class.call
    result_bundles = all_app_integrations.map(&:app_bundle).uniq

    # Must return app_integration + every AppIntegration::FOREM_APP_PLATFORMS
    expect(all_app_integrations.count).to eq(1 + AppIntegration::FOREM_APP_PLATFORMS.count)
    # Must include the app_integration and Forem App bundles
    expect(result_bundles).to include(app_integration.app_bundle, AppIntegration::FOREM_BUNDLE)
  end
end
