require "rails_helper"

RSpec.describe "Infinite scroll on dashboard", :js do
  let(:default_per_page) { 2 }
  let(:total_records) { default_per_page * 2 }
  let(:user) { create(:user) }
  let(:users) { create_list(:user, total_records) }
  let(:tags) { create_list(:tag, total_records) }
  let(:organizations) { create_list(:organization, total_records) }
  let(:podcasts) { create_list(:podcast, total_records) }

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

    it "escapes HTML characters in follower names loaded via infinite scroll", :aggregate_failures do
      users.first.update!(name: '<b class="formatted-name">Ada & Co</b>')
      older_follow = Follow.find_by!(follower: users.first, followable: user)
      older_follow.update!(created_at: 1.day.ago)

      visit "/dashboard/user_followers?per_page=#{default_per_page}"
      expect(page).to have_no_css("#follows-#{older_follow.id}")

      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
      within("#follows-#{older_follow.id}") do
        expect(page).to have_text('<b class="formatted-name">Ada & Co</b>')
        expect(page).to have_no_css("b.formatted-name")
      end
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

    it "renders tag summaries loaded via infinite scroll without double-escaping or executing HTML",
       :aggregate_failures do
      # Simulate both entity-encoded text from strip_tags and raw HTML that sanitize would permit
      tags.first.update_columns(short_summary: 'HTML &amp; CSS <b class="injected-tag">tips</b>')
      older_tag_follow = Follow.find_by!(follower: user, followable: tags.first)
      older_tag_follow.update!(created_at: 1.day.ago)

      visit dashboard_following_tags_path(per_page: default_per_page)
      expect(page).to have_no_css("#follows-#{older_tag_follow.id}")

      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
      within("#follows-#{older_tag_follow.id}") do
        expect(page).to have_text('HTML & CSS <b class="injected-tag">tips</b>')
        expect(page).to have_no_text("HTML &amp; CSS")
        expect(page).to have_no_css("b.injected-tag")
      end
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

    it "scrolls through all podcasts and shows working links", :aggregate_failures do
      page.assert_selector('div[id^="follows"]', count: total_records)
      podcasts.each do |podcast|
        expect(page).to have_link(nil, href: "/#{podcast.path}")
      end
    end
  end
end
