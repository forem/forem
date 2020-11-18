require "rails_helper"

RSpec.describe "User edits their profile", type: :system do
  let(:user) { create(:user) }
  let!(:profile_field_group) { create(:profile_field_group, name: "Ice Cream") }
  let!(:profile_field) do
    create(:profile_field, profile_field_group: profile_field_group, label: "Preferred Ice Cream Flavor")
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
      Profile.refresh_attributes!
    end

    it "renders a profile field" do
      expect(page).to have_text(profile_field.attribute_name.titleize)
    end

    it "reflects set profile fields in the interface" do
      fill_in "profile[#{profile_field.attribute_name}]", with: "chocolate"
      click_button "Save"

      expect(page).to have_text("Your profile has been updated")

      visit "/#{user.username}"

      expect(page).to have_text(profile_field.attribute_name.titleize)
      expect(page).to have_text("chocolate")
    end
  end
end
