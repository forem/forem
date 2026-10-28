require "rails_helper"

RSpec.describe "Admin profile link in user context menus" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, show_comments: true) }
  let!(:comment) { create(:comment, commentable: article, user: user) }
  let(:link_text) { "View Admin Profile" }
  let(:admin_path) { admin_user_path(user) }

  it "shows the admin profile link to admins on profile and comment menus", :aggregate_failures, :js do
    sign_in create(:user, :admin)

    visit user_profile_path(user.username)
    find_button(id: "user-profile-dropdown").click
    expect(page).to have_link(link_text, href: admin_path)

    visit article.path
    find_button(id: "comment-dropdown-trigger-#{comment.id}").click
    expect(page).to have_link(link_text, href: admin_path)
  end

  it "does not show the admin profile link to non-admins on profile and comment menus", :aggregate_failures, :js do
    sign_in create(:user, :trusted)

    visit user_profile_path(user.username)
    find_button(id: "user-profile-dropdown").click
    expect(page).to have_link(id: "user-profile-dropdownmenu-flag-button")
    expect(page).to have_no_link(link_text)

    visit article.path
    find_button(id: "comment-dropdown-trigger-#{comment.id}").click
    expect(page).to have_link("Moderate")
    expect(page).to have_no_link(link_text)
  end

  it "does not show the admin profile link when logged out on profile and comment menus", :aggregate_failures do
    visit user_profile_path(user.username)
    expect(page).to have_button(id: "user-profile-dropdown")
    expect(page).to have_no_css("#user-profile-dropdownmenu .admin-actions")
    expect(page).to have_no_link(link_text)

    visit article.path
    expect(page).to have_button(id: "comment-dropdown-trigger-#{comment.id}")
    expect(page).to have_link("Copy link")
    expect(page).to have_no_link(link_text)
  end
end
