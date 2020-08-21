require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200819025131_migrate_profile_data.rb")

describe DataUpdateScripts::MigrateProfileData do
  it "creates a profile for users who don't have one" do
    user = create(:user, :without_profile)
    expect do
      described_class.new.run
    end.to change { user.reload.profile }.from(nil).to(an_instance_of(Profile))
  end

  it "does nothing for users with existing profiles" do
    user = create(:user)
    expect { described_class.new.run }.not_to change { user.reload.profile }
  end
end
