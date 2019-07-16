require "rails_helper"

RSpec.describe "Visits Pro Memberships page", type: :system do
  let(:user) { create(:user) }

  context "when not signed in" do
    it "does not say you are a member" do
      visit "/pro"
      expect(page).not_to have_content("You already have a Pro Membership")
    end

    it "does not ask you to become a member" do
      visit "/pro"
      label = "Become a Pro member for #{ProMembership::MONTHLY_COST} credits/mo"
      expect(page).not_to have_selector("input[type=submit][value='#{label}']")
    end
  end

  context "when signed in as a regular user" do
    before do
      sign_in user
    end

    it "does not say you are a member" do
      visit "/pro"
      expect(page).not_to have_content("You already have a Pro Membership")
    end

    it "asks you to purchase credits if you don't have enough" do
      visit "/pro"
      expect(page).to have_content("Purchase #{ProMembership::MONTHLY_COST} credits")
    end

    it "asks you to become a member with enough credits" do
      create_list(:credit, 5, user: user)
      visit "/pro"
      label = "Become a Pro member for #{ProMembership::MONTHLY_COST} credits/mo"
      expect(page).to have_selector("input[type=submit][value='#{label}']")
    end
  end

  context "when signed in as as user with a pro role" do
    before do
      user.add_role(:pro)
      sign_in user
    end

    it "says you are a member" do
      visit "/pro"
      expect(page).to have_content("You already have a Pro Membership")
    end

    it "does not ask you to purchase credits if you don't have enough" do
      visit "/pro"
      expect(page).not_to have_content("Purchase #{ProMembership::MONTHLY_COST} credits")
    end

    it "does not ask you to become a member with enough credits" do
      create_list(:credit, 5, user: user)
      visit "/pro"
      label = "Become a Pro member for #{ProMembership::MONTHLY_COST} credits/mo"
      expect(page).not_to have_selector("input[type=submit][value='#{label}']")
    end

    it "does not show the status of the membership" do
      visit "/pro"
      expect(page).not_to have_content("Recharges automatically?")
    end
  end

  context "when signed in as as user with a pro membership" do
    before do
      create(:pro_membership, user: user, expires_at: 1.month.from_now)
      sign_in user
    end

    it "says you are a member" do
      visit "/pro"
      expect(page).to have_content("You already have a Pro Membership")
    end

    it "does not ask you to purchase credits if you don't have enough" do
      visit "/pro"
      expect(page).not_to have_content("Purchase #{ProMembership::MONTHLY_COST} credits")
    end

    it "does not ask you to become a member with enough credits" do
      create_list(:credit, 5, user: user)
      visit "/pro"
      label = "Become a Pro member for #{ProMembership::MONTHLY_COST} credits/mo"
      expect(page).not_to have_selector("input[type=submit][value='#{label}']")
    end

    it "shows the status of the membership" do
      visit "/pro"
      expect(page).to have_content(user.pro_membership.expires_at.to_date.to_s(:long))
      expect(page).to have_content("Recharges automatically?")
      expect(page).to have_content("Update your Pro Membership")
    end
  end
end
