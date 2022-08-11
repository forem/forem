require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220408203135_remove_profile_admin_flag.rb",
)

describe DataUpdateScripts::RemoveProfileAdminFlag do
  it "causes enabled? to be false" do
    FeatureFlag.enable(:profile_admin)

    described_class.new.run

    expect(FeatureFlag.enabled?(:profile_admin)).to be false
  end

  it "removes the profile_admin flag" do
    FeatureFlag.enable(:profile_admin)

    described_class.new.run

    expect(FeatureFlag.exist?(:profile_admin)).to be false
  end

  it "works if the flag does not exist" do
    FeatureFlag.remove(:profile_admin)

    described_class.new.run

    expect(FeatureFlag.exist?(:profile_admin)).to be false
  end
end
