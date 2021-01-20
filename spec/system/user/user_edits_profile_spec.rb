require "rails_helper"

RSpec.describe "User edits their profile", type: :system do
  let(:user) { create(:user) }
  let!(:profile_field_group) { create(:profile_field_group, name: "Ice Cream") }
  let!(:left_sidebar_profile_field) do
    create(:profile_field,
           profile_field_group: profile_field_group,
           label: "Preferred Ice Cream Flavor",
           display_area: "left_sidebar")
  end
  let!(:header_profile_field) do
    create(:profile_field,
           profile_field_group: profile_field_group,
           label: "Hate Ice Cream Flavor",
           display_area: "header")
  end
  let!(:settings_only_profile_field) do
    create(:profile_field,
           profile_field_group: profile_field_group,
           label: "Imaginary Ice Cream Flavor",
           display_area: "settings_only")
  end

  before do
    sign_in user
    visit "/settings/profile"
  end

  describe "visiting /settings/profile" do
    it "renders an error if the username contains spaces and thus is invalid" do
      fill_in "user[username]", with: "a b c"
      click_button "Save"

      expect(page).to have_text("Username is invalid")
    end

    it "makes the 'Save Button' footer sticky once a field is filled in", js: true do
      expect(page).not_to have_css(".sticky")

      fill_in "user[username]", with: "sloan"

      find_field(id: "user[username]").native.send_keys :tab # this un-focuses the filled-in field

      expect(page).to have_css(".sticky")
    end
  end

  describe "editing admin created profile fields" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)
      Profile.refresh_attributes!
    end

    it "renders profile fields" do
      expect(page).to have_text(left_sidebar_profile_field.attribute_name.titleize)
      expect(page).to have_text(header_profile_field.attribute_name.titleize)
      expect(page).to have_text(settings_only_profile_field.attribute_name.titleize)
    end

    it "reflects set profile fields in the interface" do
      fill_in "profile[#{left_sidebar_profile_field.attribute_name}]", with: "chocolate"
      fill_in "profile[#{header_profile_field.attribute_name}]", with: "pistachio"
      fill_in "profile[#{settings_only_profile_field.attribute_name}]", with: "cthulhu"
      click_button "Save"

      visit "/#{user.username}"

      expect(page).not_to have_text(settings_only_profile_field.attribute_name.titleize)
      expect(page).not_to have_text("cthulhu")

      within(".crayons-layout__sidebar-left") do
        expect(page).to have_text(left_sidebar_profile_field.attribute_name.titleize)
        expect(page).to have_text("chocolate")
      end

      within(".profile-header") do
        expect(page).to have_text(header_profile_field.attribute_name.titleize)
        expect(page).to have_text("pistachio")
      end
    end
  end
end
