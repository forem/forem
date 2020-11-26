require "rails_helper"

RSpec.describe "Admin manages profile fields", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let!(:profile_field_group) { create(:profile_field_group, name: "Delete Me") }
  let(:label) { "Delete Me Too" }

  before do
    create(:profile_field, profile_field_group: profile_field_group, label: label)
    Profile.refresh_attributes!
    allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)

    sign_in admin
    visit admin_profile_fields_path
  end

  it "adds a profile group" do
    click_button "Add group"
    find("#add-group-modal #profile_field_group_name").set("Example group")
    click_on "Create Profile field group"
    expect(page).to have_text("Successfully created group: Example group")
  end

  it "adds a profile field" do
    group_name = profile_field_group.name.gsub(/\s+/, "_")
    within(find("#profile-field-group-#{profile_field_group.id}")) do
      click_button("Add Field")
      input = find("#add-#{group_name}-profile-field-modal #profile_field_label")
      input.set("Example field")
      click_on "Create Profile field"
    end
    expect(page).to have_text("Profile field Example field created")
  end

  it "deletes a profile_field_group" do
    find("#profile-field-group-#{profile_field_group.id}").click_button("Delete Group")
    expect(page).to have_text("Group #{profile_field_group.name} deleted")
  end

  it "deletes a profile_field" do
    profile_field = ProfileField.find_by(label: label)
    expect(page).to have_text(profile_field.label.to_s)
    find("#profile-field-#{profile_field.id}").click_button("Delete Profile Field")
    expect(page).to have_text("Profile field #{label} deleted")
  end
end
