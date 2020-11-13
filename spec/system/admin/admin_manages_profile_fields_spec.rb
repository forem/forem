require "rails_helper"

RSpec.describe "Admin manages profile fields", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let!(:profile_field_group) { create(:profile_field_group, name: "Delete Me!") }
  let!(:profile_field) { create(:profile_field, profile_field_group: profile_field_group, label: "Delete Me Too!") }

  before do
    FeatureFlag.enable(:profile_admin)
    sign_in admin
    visit admin_profile_fields_path
  end

  after do
    FeatureFlag.disable(:profile_admin)
  end

  it "adds a profile group" do
    click_on "Add group"
    first("input#profile_field_group_name", visible: true).set("Example group")
    click_on "Create Profile field group"
    expect(page).to have_text("Successfully created group: Example group")
  end

  it "adds a profile field" do
    click_on "Add Field"
    first("input#profile_field_label", visible: true).set("Example field")
    click_on "Create Profile field"
    expect(page).to have_text("Profile field Example field created")
  end

  it "deletes a profile_field_group" do
    click_button "Delete Group"
    expect(page).to have_text("Group #{profile_field_group.name} deleted")
  end

  it "deletes a profile_field" do
    expect(page).to have_text(profile_field.label.to_s)
    click_button "Delete Profile Field"
    expect(page).to have_text("Profile field #{profile_field.label} deleted")
  end
end
