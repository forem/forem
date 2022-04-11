require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220408154416_enable_profile_admin_feature.rb",
)

describe DataUpdateScripts::EnableProfileAdminFeature do
  after do
    FeatureFlag.remove(:profile_admin)
  end

  it "enables the :profile_admin flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.enabled?(:profile_admin) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:profile_admin)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:profile_admin) }
  end

  it "works if the flag is already enabled" do
    FeatureFlag.enable(:profile_admin)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.enabled?(:profile_admin) }
  end
end
