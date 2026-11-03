require "rails_helper"

RSpec.describe "User edits their profile" do
  let(:user) { create(:user) }
  let(:profile_field_group) { create(:profile_field_group, name: "Ice Cream") }
  let(:left_sidebar_profile_field) do
    create(:profile_field,
           profile_field_group: profile_field_group,
           label: "Preferred Ice Cream Flavor",
           display_area: "left_sidebar")
  end
  let(:header_profile_field) do
    create(:profile_field,
           profile_field_group: profile_field_group,
           label: "Hate Ice Cream Flavor",
           display_area: "header")
  end

  before do
    sign_in user
  end

  describe "visiting /settings/profile" do
    before { visit "/settings/profile" }

    it "renders an error if the username contains spaces and thus is invalid" do
      fill_in "user[username]", with: "a b c"
      click_on "Save"

      expect(page).to have_text("Username is invalid")
    end

    it "makes the 'Save Button' footer sticky once a field is filled in", :js do
      expect(page).to have_no_css(".sticky")

      fill_in "user[username]", with: "sloan"

      find_field(id: "user[username]").native.send_keys :tab # this un-focuses the filled-in field

      expect(page).to have_css(".sticky")
    end
  end

  describe "editing admin created profile fields" do
    before do
      left_sidebar_profile_field
      header_profile_field
      Profile.refresh_attributes!
      visit "/settings/profile"
    end

    it "renders and saves dynamic and static profile fields", :aggregate_failures do
      expect(page).to have_text(left_sidebar_profile_field.label.titleize)
      expect(page).to have_text(header_profile_field.label.titleize)

      fill_in "profile[#{left_sidebar_profile_field.attribute_name}]", with: "chocolate"
      fill_in "profile[#{header_profile_field.attribute_name}]", with: "pistachio"
      fill_in "profile[summary]", with: "Star of hit 90s sitcom Horsin' Around"
      fill_in "profile[location]", with: "Hollywoo"
      click_on "Save"

      visit "/#{user.username}"

      expect(page).to have_no_text("cthulhu")

      within(".crayons-layout__sidebar-left") do
        expect(page).to have_text(left_sidebar_profile_field.label.titleize)
        expect(page).to have_text("chocolate")
      end

      within(".profile-header") do
        expect(page).to have_text(header_profile_field.label.titleize)
        expect(page).to have_text("pistachio")
      end

      expect(page).to have_text("Horsin' Around")
      expect(page).to have_text("Hollywoo")
    end
  end
end
