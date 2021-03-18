require "rails_helper"

RSpec.describe "User devices routes", type: :routing do
  it "renders the user devices routes if the mobile_notifications feature flag is enabled", :aggregate_failures do
    allow(FeatureFlag).to receive(:enabled?).twice.with(:mobile_notifications).and_return(true)

    expect(post: devices_path).to route_to(
      controller: "devices",
      action: "create",
      format: :json,
      locale: nil,
    )

    expect(delete: "#{devices_path}/1").to route_to(
      controller: "devices",
      action: "destroy",
      id: "1",
      format: :json,
      locale: nil,
    )
  end

  it "does not render the user devices routes if the mobile_notifications feature flag is disabled",
     :aggregate_failures do
    allow(FeatureFlag).to receive(:enabled?).at_least(:twice).with(:mobile_notifications).and_return(false)

    expect(post: devices_path).not_to route_to(
      controller: "devices",
      action: "create",
      format: :json,
      locale: nil,
    )

    expect(delete: "#{devices_path}/1").not_to route_to(
      controller: "devices",
      action: "destroy",
      id: "1",
      format: :json,
      locale: nil,
    )
  end
end
