require "rails_helper"

RSpec.describe "Dashboard", type: :system, js: true do
  let(:user) { create(:user) }
  let(:listing) { create(:listing) }
  let(:collection) { create(:collection, :with_articles) }
  let(:collection_user) { collection.user }

  before do
    sign_in user
  end

  context "when looking at analytics counters" do
    it "shows the count of unspent credits" do
      Credit.add_to(user, 2)

      Credits::Buy.call(
        purchaser: user,
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
      sign_in collection_user
    end

    it "shows the user-collections count on dashboard tab" do
      visit dashboard_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end

    it "shows the user-collections count on following tab" do
      visit dashboard_following_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end

    it "shows the user-collections count on following-tags tab" do
      visit dashboard_following_tags_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end

    it "shows the user-collections count on following-users tab" do
      visit dashboard_following_users_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end

    it "shows the user-collections count on following-orgs tab" do
      visit dashboard_following_organizations_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end

    it "shows the user-collections count on following-podcasts tab" do
      visit dashboard_following_podcasts_path

      within "main#main-content nav" do
        expect(page).to have_text(/Series\n1/)
      end
    end
  end
end
