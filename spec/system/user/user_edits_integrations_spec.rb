require "rails_helper"

RSpec.describe "User edits their profile", type: :system, js: true do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
  end

  describe "via visiting /settings" do
    it "goes to /settings" do
      visit "/settings"
      expect(page).to have_current_path("/settings")

      click_link "Integrations"

      fill_in "Twitch Username", with: "TestTwitchUser"
      click_button("SUBMIT")

      expect(page).to have_content "Your profile was successfully updated."

      click_link "Integrations"
      expect(find_field("Twitch Username").value).to eq "TestTwitchUser"
    end
  end
end
