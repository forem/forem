require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210107151449_remove_feeds_import_feature_flag.rb",
)

describe DataUpdateScripts::RemoveFeedsImportFeatureFlag do
  it "removes the :feeds_import flag" do
    FeatureFlag.enable(:feeds_import)

    described_class.new.run

    expect(FeatureFlag.exist?(:feeds_import)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:feeds_import)).to be(false)
  end
end
