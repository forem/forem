require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220113085122_enable_creator_onboarding_feature_flag.rb",
)

describe DataUpdateScripts::EnableCreatorOnboardingFeatureFlag do
  after do
    FeatureFlag.remove(:creator_onboarding)
  end

  it "adds the :creator_onboarding flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:creator_onboarding) }.from(false).to(true)
  end

  it "enables the :creator_onboarding flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.enabled?(:creator_onboarding) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:creator_onboarding)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:creator_onboarding) }
  end

  it "works if the flag is already enabled" do
    FeatureFlag.enable(:creator_onboarding)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.enabled?(:creator_onboarding) }
  end
end
