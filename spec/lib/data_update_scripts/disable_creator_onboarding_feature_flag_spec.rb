require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220422141135_disable_creator_onboarding_feature_flag.rb",
)

describe DataUpdateScripts::DisableCreatorOnboardingFeatureFlag do
  it "disables the :creator_onboarding feature flag" do
    FeatureFlag.enable(:creator_onboarding)

    described_class.new.run

    expect(FeatureFlag.enabled?(:creator_onboarding)).to be(false)
  end

  it "works if not already enabled" do
    described_class.new.run

    expect(FeatureFlag.enabled?(:creator_onboarding)).to be(false)
  end
end
