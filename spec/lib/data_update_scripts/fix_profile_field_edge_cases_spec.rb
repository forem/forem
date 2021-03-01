require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210211164634_fix_profile_field_edge_cases.rb",
)

describe DataUpdateScripts::FixProfileFieldEdgeCases do
  it "migrates profile fields to proper areas" do
    # Run the script
    described_class.new.run
    expect(ProfileField.find_by(attribute_name: "git_lab_url").display_area)
      .to eq("settings_only")
    expect(ProfileField.find_by(attribute_name: "skills_languages").display_area).to eq("left_sidebar")
  end
end
