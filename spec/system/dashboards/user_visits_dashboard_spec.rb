require "rails_helper"

RSpec.describe "Dashboard", type: :system, js: true do
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:podcast) { create(:podcast) }
  let(:listing) { create(:listing) }
  let(:collection) { create(:collection, :with_articles) }
  let(:user1) { collection.user }
  let(:user2) { create(:user) }

  context "when looking at analytics counters" do
    before do
      sign_in user1
    end

    it "shows the count of unspent credits" do
      Credit.add_to(user1, 2)

      Credits::Buy.call(
        purchaser: user1,
        purchase: listing,
        cost: 1,
      )
      Credit.counter_culture_fix_counts
      user.reload

      visit dashboard_path

      within "main#main-content > header" do
        expect(page).to have_text(/1\nCredits available/)
      end
    end
  end

  context "when looking at actions panel" do
    before do
      stub_const(
        "DASHBOARD_PATHS",
        [
          dashboard_path,
          dashboard_following_path,
          dashboard_following_tags_path,
          dashboard_following_users_path,
          dashboard_following_organizations_path,
          dashboard_following_podcasts_path,
        ],
      )
      [user2, tag, organization, podcast].each do |item|
        user1.follow(item)
      end
      user2.follow(user1)

      user1.reload
      user2.reload
    end

    it "shows the correct posts count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          # the collection contains 3 posts
          expect(page).to have_text(/Posts\n3/)
        end
      end
    end

    it "shows the correct series count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Series\n1/)
        end
      end
    end

    it "shows the correct followers count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Followers\n1/)
        end
      end
    end

    it "shows the correct following-tags count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Following tags\n1/)
        end
      end
    end

    it "shows the correct following-users count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Following users\n1/)
        end
      end
    end

    it "shows the correct following-organizations count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Following organizations\n1/)
        end
      end
    end

    it "shows the correct following-podcasts count on current dashboard tab", :aggregate_failures do
      DASHBOARD_PATHS.each do |path|
        sign_in user1
        visit path

        within "main#main-content nav" do
          expect(page).to have_text(/Following podcasts\n1/)
        end
      end
    end
  end
end
