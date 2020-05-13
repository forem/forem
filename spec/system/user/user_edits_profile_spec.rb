require "rails_helper"

RSpec.describe "User edits their profile", type: :system do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
  end

  describe "visiting /settings/profile" do
    it "renders an error if the username contains spaces and thus is invalid" do
      visit "/settings/profile"

      fill_in "user[username]", with: "a b c"
      click_button "Save"

      expect(page).to have_text("Username is invalid")
    end
  end
end
