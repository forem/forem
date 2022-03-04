require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211020145958_remove_passport_feature_flag.rb",
)

describe DataUpdateScripts::RemovePassportFeatureFlag do
  it "removes the :forem_passport flag" do
    FeatureFlag.enable(:forem_passport)

    described_class.new.run

    expect(FeatureFlag.exist?(:forem_passport)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:forem_passport)).to be(false)
  end
end
