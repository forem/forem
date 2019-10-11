require "rails_helper"

RSpec.describe "Infinite scroll on dashboard", type: :system, js: true do
  let(:user) { create(:user) }
  let(:default_per_page) { 81 }
  let(:users) { create_list(:user, default_per_page) }
  let(:tags) { create_list(:tag, default_per_page) }
  let(:organizations) { create_list(:organization, default_per_page) }
  let(:podcasts) { create_list(:podcast, default_per_page) }

  context "when /dashboard/user_followers is visited" do
    before do
      sign_in user
      users.each do |u|
        create(:follow, follower: u, followable: user)
      end
    end

    it "scrolls through all users" do
      visit "/dashboard/user_followers"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: default_per_page)
    end
  end

  context "when /dashboard/following_tags is visited" do
    before do
      sign_in user
      tags.each do |tag|
        create(:follow, follower: user, followable: tag)
      end
    end

    it "scrolls through all tags" do
      visit "/dashboard/following_tags"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: default_per_page)
    end
  end

  context "when /dashboard/following_users is visited" do
    before do
      sign_in user
      users.each do |u|
        create(:follow, follower: user, followable: u)
      end
    end

    it "scrolls through all users" do
      visit "/dashboard/following_users"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: default_per_page)
    end
  end

  context "when /dashboard/following_organizations is visited" do
    before do
      sign_in user
      organizations.each do |organization|
        create(:follow, follower: user, followable: organization)
      end
    end

    it "scrolls through all users" do
      visit "/dashboard/following_organizations"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: default_per_page)
    end
  end

  context "when /dashboard/following_podcasts is visited" do
    before do
      sign_in user
      podcasts.each do |podcast|
        create(:follow, follower: user, followable: podcast)
      end
    end

    it "scrolls through all users" do
      visit "/dashboard/following_podcasts"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: default_per_page)
    end
  end
end
