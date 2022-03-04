require "rails_helper"

RSpec.describe "Data Update Scripts admin routes", type: :routing do
  it "renders the data update scripts admin route if the feature flag is enabled" do
    allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(true)

    expect(get: admin_data_update_scripts_path).to route_to(
      controller: "admin/data_update_scripts",
      action: "index",
      locale: nil,
    )
  end

  it "does not render the data update scripts admin route if the feature flag is disabled" do
    allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(false)

    expect(get: admin_data_update_scripts_path).not_to route_to(
      controller: "admin/data_update_scripts",
      action: "index",
      locale: nil,
    )
  end
end
