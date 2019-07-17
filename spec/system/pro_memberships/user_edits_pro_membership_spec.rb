require "rails_helper"

RSpec.describe "Edit Pro Membership", type: :system do
  let(:user) { create(:user) }

  context "when signed in as as user with a pro membership" do
    before do
      create(:pro_membership, user: user, expires_at: 1.month.from_now)
      sign_in user
    end

    it "works correctly" do
      visit "/pro/edit"
      expect(page).to have_content("Edit your Pro Membership")
    end

    it "updates a pro membership" do
      visit "/pro/edit"
      check "Top up from credit card?"
      click_on "Update your Membership"
      expect(page).to have_content("Like a Pro")
    end
  end
end
