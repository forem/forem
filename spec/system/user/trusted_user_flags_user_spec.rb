require "rails_helper"

RSpec.describe "Flagging users from profile pages", type: :system, js: true do
  let(:user) { create :user }
  let(:flag_text) { "Flag @#{user.username}" }

  context "when not logged in" do
    it "does not show the flag button" do
      visit user_profile_path(user.username)
      click_button(id: "user-profile-dropdown")
      expect(page).not_to have_link(flag_text)
    end
  end

  context "when signed in as a non-trusted user" do
    it "does not show the flag button" do
      sign_in create(:user)

      # TODO: Fix me! Loading the page twice here ensures that the dropdown menu
      # does not include the "Flag @username" option. This is a band-aid solution
      # in order to get this spec to consistently pass and unblock builds.
      2.times do
        visit user_profile_path(user.username)
      end

      click_button(id: "user-profile-dropdown")
      expect(page).not_to have_link(flag_text)
    end
  end

  context "when signed in as the user" do
    it "does not show a button for flagging yourself" do
      sign_in user

      visit user_profile_path(user.username)
      expect(page).not_to have_selector("user-profile-dropdown")
    end
  end

  context "when signed in as a trusted user" do
    it "allows toggling the flagged status" do
      sign_in create(:user, :trusted)

      visit user_profile_path(user.username)
      click_button(id: "user-profile-dropdown")
      expect(page).to have_link(flag_text)
    end
  end
end
