require "rails_helper"

RSpec.describe "Admin profile link in user context menus", :js do
  let(:user) { create(:user) }
  let(:link_text) { "View Admin Profile" }
  let(:admin_path) { admin_user_path(user) }

  context "when viewing a profile page" do
    it "shows the admin profile link to admins" do
      sign_in create(:user, :admin)

      visit user_profile_path(user.username)
      find_button(id: "user-profile-dropdown").click

      expect(page).to have_link(link_text, href: admin_path)
    end

    it "does not show the admin profile link to non-admins" do
      sign_in create(:user, :trusted)

      visit user_profile_path(user.username)
      find_button(id: "user-profile-dropdown").click

      expect(page).to have_link(id: "user-profile-dropdownmenu-flag-button")
      expect(page).to have_no_link(link_text)
    end

    it "does not show the admin profile link when logged out" do
      visit user_profile_path(user.username)
      find_button(id: "user-profile-dropdown").click

      expect(page).to have_no_link(link_text)
    end
  end

  context "when viewing a comment" do
    let(:article) { create(:article, show_comments: true) }
    let!(:comment) { create(:comment, commentable: article, user: user) }

    it "shows the admin profile link to admins" do
      sign_in create(:user, :admin)

      visit article.path
      find_button(id: "comment-dropdown-trigger-#{comment.id}").click

      expect(page).to have_link(link_text, href: admin_path)
    end

    it "does not show the admin profile link to non-admins" do
      sign_in create(:user, :trusted)

      visit article.path
      find_button(id: "comment-dropdown-trigger-#{comment.id}").click

      expect(page).to have_link("Moderate")
      expect(page).to have_no_link(link_text)
    end
  end
end
