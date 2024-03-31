require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230725143428_add_billboard_location_targeting_feature_flag.rb",
)

describe DataUpdateScripts::AddBillboardLocationTargetingFeatureFlag do
  before do
    allow(FeatureFlag).to receive(:add)
  end

  it "adds the feature flag" do
    described_class.new.run
    expect(FeatureFlag).to have_received(:add).with(:billboard_location_targeting)
  end
end
