require "rails_helper"

RSpec.describe "Infinite scroll on dashboard", type: :system, js: true do
  let(:default_per_page) { 3 }
  let(:total_records) { default_per_page * 2 }
  let(:user) { create(:user) }
  let!(:users) { create_list(:user, total_records) }
  let!(:tags) { create_list(:tag, total_records) }
  let!(:organizations) { create_list(:organization, total_records) }
  let!(:podcasts) { create_list(:podcast, total_records) }

  before do
    sign_in user
  end

  context "when /dashboard/user_followers is visited" do
    before do
      users.each do |u|
        create(:follow, follower: u, followable: user)
      end

      visit "/dashboard/user_followers?per_page=#{default_per_page}"
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_tags is visited" do
    before do
      tags.each do |tag|
        create(:follow, follower: user, followable: tag)
      end
      visit dashboard_following_tags_path(per_page: default_per_page)

      page.execute_script("window.scrollTo(0, 100000)")
    end

    it "scrolls through all tags" do
      page.assert_selector('div[id^="follows"]', count: total_records)
    end

    it "updates two tag point values" do
      last_divs = page.all('div[id^="follows"]').last(2)

      within(last_divs[0]) { fill_in with: 5.0, class: "crayons-textfield" }
      within(last_divs[1]) { fill_in with: 10.0, class: "crayons-textfield" }

      click_button "commit"

      first_divs = page.all('div[id^="follows"]').first(2)
      within(first_divs[0]) { expect(page).to have_field(with: 10.0, class: "crayons-textfield") }
      within(first_divs[1]) { expect(page).to have_field(with: 5.0, class: "crayons-textfield") }
    end
  end

  context "when /dashboard/following_users is visited" do
    before do
      users.each do |u|
        create(:follow, follower: user, followable: u)
      end

      visit dashboard_following_users_path(per_page: default_per_page)
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_organizations is visited" do
    before do
      organizations.each do |organization|
        create(:follow, follower: user, followable: organization)
      end

      visit dashboard_following_organizations_path(per_page: default_per_page)
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_podcasts is visited" do
    before do
      podcasts.each do |podcast|
        create(:follow, follower: user, followable: podcast)
      end
      visit dashboard_following_podcasts_path(per_page: default_per_page)

      page.execute_script("window.scrollTo(0, 100000)")
    end

    it "scrolls through all podcasts" do
      page.assert_selector('div[id^="follows"]', count: total_records)
    end

    it "shows working links" do
      podcasts.each do |podcast|
        expect(page).to have_link(nil, href: "/#{podcast.path}")
      end
    end
  end
end
