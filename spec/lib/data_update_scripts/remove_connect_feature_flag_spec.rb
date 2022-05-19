require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220330191441_remove_connect_feature_flag.rb",
)

describe DataUpdateScripts::RemoveConnectFeatureFlag do
  it "removes the connect feature flag" do
    FeatureFlag.add(:connect)

    described_class.new.run

    expect(FeatureFlag.exist?(:connect)).to be false
  end
end
