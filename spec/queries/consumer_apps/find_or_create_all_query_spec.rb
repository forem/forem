require "rails_helper"

RSpec.describe ConsumerApps::FindOrCreateAllQuery, type: :query do
  let!(:consumer_app) { create(:consumer_app) }

  it "fetches all ConsumerApp including the Forem apps" do
    all_consumer_apps = described_class.call
    result_bundles = all_consumer_apps.map(&:app_bundle).uniq

    # Must return consumer_app + every ConsumerApp::FOREM_APP_PLATFORMS
    expect(all_consumer_apps.count).to eq(1 + ConsumerApp::FOREM_APP_PLATFORMS.count)
    # Must include the consumer_app and Forem App bundles
    expect(result_bundles).to include(consumer_app.app_bundle, ConsumerApp::FOREM_BUNDLE)
  end
end
