require "rails_helper"

RSpec.describe "Flagging users from profile pages" do
  let(:user) { create(:user) }
  let(:unflag_text) { "Unflag @#{user.username}" }
  let(:flag_text) { "Flag @#{user.username}" }

  context "when not logged in" do
    it "does not show the flag button", :aggregate_failures do
      visit user_profile_path(user.username)
      expect(page).to have_button(id: "user-profile-dropdown")
      expect(page).to have_no_selector("#user-profile-dropdownmenu-flag-button")
      expect(page).to have_no_link(flag_text)
    end
  end

  context "when signed in as a non-trusted user" do
    it "does not show the flag button", :js do
      sign_in create(:user)

      visit user_profile_path(user.username)

      click_on(id: "user-profile-dropdown")
      expect(page).to have_no_link(flag_text)
    end
  end

  context "when signed in as a trusted user" do
    let(:trusted_user) { create(:user, :trusted) }

    it "hides self-flagging on own profile and allows toggling the flagged status on another user", :js do
      sign_in trusted_user

      visit user_profile_path(trusted_user.username)
      expect(page).to have_no_selector("#user-profile-dropdownmenu-flag-button", visible: :all)

      visit user_profile_path(user.username)
      click_on(id: "user-profile-dropdown")
      expect(page).to have_no_selector("#user-profile-dropdownmenu-spam-button")

      accept_confirm do
        click_on(id: "user-profile-dropdownmenu-flag-button")
      end
      expect(page).to have_link(unflag_text)
    end
  end
end
