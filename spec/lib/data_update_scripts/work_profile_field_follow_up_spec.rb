require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210712044513_work_profile_field_follow_up.rb",
)

describe DataUpdateScripts::WorkProfileFieldFollowUp do
  it "removes the three obsolete profile fields" do
    ProfileField.find_or_create_by(label: "Employer name")
    ProfileField.find_or_create_by(label: "Employer URL")
    ProfileField.find_or_create_by(label: "Employment title")

    expect { described_class.new.run }.to change(ProfileField, :count).by(-3)
  end

  it "changes the group of the work field" do
    work_field = ProfileField.find_or_create_by(attribute_name: "work", label: "Work")
    work_field.update(profile_field_group: nil) # ensure we start without a group
    work_group = ProfileFieldGroup.find_or_create_by(name: "Work")

    expect { described_class.new.run }
      .to change { work_field.reload.profile_field_group }.from(nil).to(work_group)
  end
end
