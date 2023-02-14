require "rails_helper"

RSpec.describe "/admin/advanced/extensions" do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
  end

  after do
    FeatureFlag.remove(:listing_feature)
  end

  it "returns the listings extension", :aggregate_failures do
    get admin_extensions_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Listings")
  end

  it "toggles the listings extension" do
    expect do
      post toggle_admin_extensions_path, params: {
        "listing_feature" => "1"
      }
    end.to change { FeatureFlag.enabled?(:listing_feature) }.from(false).to(true)
  end
end
