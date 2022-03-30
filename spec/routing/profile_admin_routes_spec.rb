require "rails_helper"

RSpec.describe "Profile admin routes", type: :routing do
  it "renders the profile admin route if the feature flag is enabled" do
    expect(get: admin_profile_fields_path).to route_to(
      controller: "admin/profile_fields",
      action: "index",
      locale: nil,
    )
  end

  it "renders the profile admin route even if the feature flag is disabled" do
    allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(false)

    expect(get: admin_profile_fields_path).to route_to(
      controller: "admin/profile_fields",
      action: "index",
      locale: nil,
    )
  end
end
