require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210506052235_remove_runtime_banner_feature_flag.rb",
)

describe DataUpdateScripts::RemoveRuntimeBannerFeatureFlag do
  it "removes the :runtime_banner flag" do
    FeatureFlag.enable(:runtime_banner)

    described_class.new.run

    expect(FeatureFlag.exist?(:runtime_banner)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:runtime_banner)).to be(false)
  end
end
