require "rails_helper"

RSpec.describe "/admin/advanced/feature_flags", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
  end

  after do
    FeatureFlag.remove(:listing_feature)
  end

  it "returns the listings feature flag", :aggregate_failures do
    get admin_feature_flags_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Listings")
  end

  it "toggles the listings feature flag" do
    expect do
      post toggle_flags_admin_feature_flags_path, params: {
        "listing_feature" => "1"
      }
    end.to change { FeatureFlag.enabled?(:listing_feature) }.from(false).to(true)
  end
end
