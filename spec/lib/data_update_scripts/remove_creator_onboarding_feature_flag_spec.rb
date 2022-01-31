require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220131185747_remove_creator_onboarding_feature_flag.rb",
)

describe DataUpdateScripts::RemoveCreatorOnboardingFeatureFlag do
  it "removes the :creator_onboarding feature flag" do
    FeatureFlag.enable(:creator_onboarding)

    described_class.new.run

    expect(FeatureFlag.exist?(:creator_onboarding)).to be(false)
  end

  it "works if the :creator_onboarding feature flag is not available" do
    described_class.new.run

    expect(FeatureFlag.exist?(:creator_onboarding)).to be(false)
  end
end
