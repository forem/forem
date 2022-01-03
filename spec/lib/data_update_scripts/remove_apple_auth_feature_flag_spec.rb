require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210803161945_remove_apple_auth_feature_flag.rb",
)

describe DataUpdateScripts::RemoveAppleAuthFeatureFlag do
  it "removes the :apple_auth flag" do
    FeatureFlag.enable(:apple_auth)

    described_class.new.run

    expect(FeatureFlag.exist?(:apple_auth)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:apple_auth)).to be(false)
  end
end
