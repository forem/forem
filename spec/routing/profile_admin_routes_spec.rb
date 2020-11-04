require "rails_helper"

RSpec.describe "Profile admin routes", type: :routing do
  it "renders the profile admin route if the feature flag is enabled" do
    allow(Flipper).to receive(:enabled?).with(:profile_admin).and_return(true)

    expect(get: admin_profile_fields_path).to route_to(
      controller: "admin/profile_fields",
      action: "index",
      locale: nil,
    )
  end

  it "does not render the profile admin route if the feature flag is disabled" do
    allow(Flipper).to receive(:enabled?).with(:profile_admin).and_return(false)

    expect(get: admin_profile_fields_path).not_to route_to(
      controller: "admin/profile_fields",
      action: "index",
      locale: nil,
    )
  end
end
