require "rails_helper"

RSpec.describe "Profile admin routes" do
  it "renders the profile admin route" do
    expect(get: admin_profile_fields_path).to route_to(
      controller: "admin/profile_fields",
      action: "index",
      locale: nil,
    )
  end
end
