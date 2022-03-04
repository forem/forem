require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220217144931_remove_detect_animated_images_feature_flag.rb",
)

describe DataUpdateScripts::RemoveDetectAnimatedImagesFeatureFlag do
  it "removes the :detect_animated_images flag" do
    FeatureFlag.enable(:detect_animated_images)

    described_class.new.run

    expect(FeatureFlag.exist?(:detect_animated_images)).to be(false)
  end

  it "works if the flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:detect_animated_images)).to be(false)
  end
end
