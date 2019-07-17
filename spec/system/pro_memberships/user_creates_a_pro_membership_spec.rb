require "rails_helper"

RSpec.describe "Visits Pro Memberships page", type: :system do
  let(:user) { create(:user) }

  context "when signed in as a regular user with enough credits" do
    before do
      create_list(:credit, 5, user: user)
      sign_in user
    end

    it "makes the user become a pro" do
      visit "/pro"
      label = "Become a Pro member for #{ProMembership::MONTHLY_COST} credits/mo"
      click_on label
      expect(page).to have_content("You are now a Pro!")
    end
  end
end
