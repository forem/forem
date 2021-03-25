require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201223013903_set_proper_display_area_for_profile_fields.rb",
)

describe DataUpdateScripts::SetProperDisplayAreaForProfileFields do
  it "migrates profile fields to proper areas" do
    # Run the script
    described_class.new.run
    expect(ProfileField.find_by(attribute_name: "instagram_url").display_area)
      .to eq("settings_only")
    expect(ProfileField.find_by(attribute_name: "education").display_area).to eq("header")
    expect(ProfileField.find_by(attribute_name: "currently_learning").display_area).to eq("left_sidebar")
  end
end
