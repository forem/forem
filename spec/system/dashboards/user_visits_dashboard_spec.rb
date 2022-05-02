require "rails_helper"

RSpec.describe "Dashboard", type: :system, js: true do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:article) { create(:article, user: user1) }
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:podcast) { create(:podcast) }
  let(:listing) { create(:listing) }
  let(:collection) { create(:collection, :with_articles, user: user1) }

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
    it "shows the user-collections count on current dashboard tab", :aggregate_failures do
      dashboard_paths = [
        dashboard_path,
        # dashboard_following_path,
        # dashboard_following_tags_path,
        # dashboard_following_users_path,
        # dashboard_following_organizations_path,
        # dashboard_following_podcasts_path,
      ]

      user1.follow(user2)
      user2.follow(user1)
      user1.follow(tag)
      user1.follow(organization)
      user1.follow(podcast)

      user1.reload
      user2.reload

      dashboard_paths.each do |path|
        sign_in user1
        visit path
        # save_and_open_page

        # within "main#main-content nav" do
        #   expect(page).to have_text(/Series\n1/)
        # end
      end
    end
  end
end
