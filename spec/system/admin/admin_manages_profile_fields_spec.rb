require "rails_helper"

RSpec.describe "Admin manages profile fields" do
  let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let!(:profile_field_group) { create(:profile_field_group, name: "Delete Me") }
  let(:label) { "Delete Me Too" }
  let!(:profile_field) { create(:profile_field, profile_field_group: profile_field_group, label: label) }

  before do
    Profile.refresh_attributes!
    sign_in admin
    visit admin_profile_fields_path
  end

  it "adds and deletes profile field groups and profile fields", :aggregate_failures do
    click_on "Add group"
    find("#add-group-modal #profile_field_group_name").set("Example group")
    click_on "Create Profile field group"
    expect(page).to have_text("Successfully created group: Example group")

    group_name = profile_field_group.name.gsub(/\s+/, "_")
    within("#profile-field-group-#{profile_field_group.id}") do
      click_on("Add Field")
      input = find("#add-#{group_name}-profile-field-modal #profile_field_label")
      input.set("Example field")
      click_on "Create Profile field"
    end
    expect(page).to have_text("Profile field Example field created")

    expect(page).to have_text(profile_field.label.to_s)
    find("#profile-field-group-summary-#{profile_field_group.id}").click
    find("#profile-field-summary-#{profile_field.id}").click
    find("#profile-field-#{profile_field.id}").click_on("Delete Profile Field")
    expect(page).to have_text("Profile field #{label} deleted")

    find("#profile-field-group-#{profile_field_group.id}").click_on("Delete Group")
    expect(page).to have_text("Group #{profile_field_group.name} deleted")
  end
end
