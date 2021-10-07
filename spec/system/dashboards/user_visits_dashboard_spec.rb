require "rails_helper"

RSpec.describe "Dashboard", type: :system, js: true do
  let(:user) { create(:user) }
  let(:listing) { create(:listing) }

  before do
    sign_in user
  end

  context "when looking at analytics counters" do
    it "shows the count of unspent credits" do
      Credit.add_to(user, 2)

      Credits::Buyer.call(
        purchaser: user,
        purchase: listing,
        cost: 1,
      )
      Credit.counter_culture_fix_counts
      user.reload

      visit dashboard_path

      within "main#main-content > section" do
        expect(page).to have_text("1\nCredits available")
      end
    end
  end
end
