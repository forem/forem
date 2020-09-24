require "rails_helper"

RSpec.describe "User edits their profile", type: :system do
  let(:user) { create(:user, saw_onboarding: true) }

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

      fill_in "user[website_url]", with: "example.com"

      find("#user_website_url").native.send_keys :tab # this un-focuses the filled-in field

      expect(page).to have_css(".sticky")
    end
  end
end
