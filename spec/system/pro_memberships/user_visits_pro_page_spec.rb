require "rails_helper"

RSpec.describe "Visits Pro Memberships page", type: :system do
  let(:user) { create(:user) }

  context "when not signed in" do
    it "does not say you are a member" do
      visit "/pro"
      expect(page).not_to have_content("View your Pro Membership")
    end

    it "does not ask to become a pro member" do
      visit "/pro"

      expect(page).not_to have_content("Become a Pro member")
    end
  end

  context "when signed in as a regular user" do
    before do
      sign_in user
    end

    it "does not say you are a member" do
      visit "/pro"
      expect(page).not_to have_content("View your Pro Membership")
    end

    it "asks to become a pro member" do
      visit "/pro"

      expect(page).to have_content("Become a Pro member")
    end
  end

  context "when signed in as as user with a pro role" do
    before do
      user.add_role(:pro)
      sign_in user
    end

    it "says you are a member" do
      visit "/pro"
      expect(page).to have_content("View your Pro Membership")
    end

    it "does not ask to become a pro member" do
      visit "/pro"
      expect(page).not_to have_content("Become a Pro member")
    end
  end

  context "when signed in as as user with a pro membership" do
    before do
      create(:pro_membership, user: user, expires_at: 1.month.from_now)
      sign_in user
    end

    it "says you are a member" do
      visit "/pro"
      expect(page).to have_content("View your Pro Membership")
    end

    it "does not ask to become a pro member" do
      visit "/pro"
      expect(page).not_to have_content("Become a Pro member")
    end
  end
end
