require "rails_helper"

RSpec.describe "Visits Pro Membership settings page", type: :system do
  let(:user) { create(:user) }
  let(:cost) { ProMembership::MONTHLY_COST }

  context "when signed in as a regular user" do
    before do
      sign_in user
    end

    it "contains the correct info if you have no credits" do
      visit "/settings/pro-membership"

      expect(page).to have_content("Pro Membership is #{cost} credits per month")
      expect(page).to have_content("You currently have no credits, you need #{cost} to become a Pro member")
      expect(page).to have_link("Purchase credits", href: "/credits/purchase")
      expect(page).to have_link("Pro Membership page", href: "/pro")
    end

    it "contains the correct info if you have some credits but not enough" do
      create(:credit, user: user)

      visit "/settings/pro-membership"
      expect(page).to have_content("Pro Membership is #{cost} credits per month")
      expect(page).to have_content(
        "You currently have #{cost - 1} credits, you need #{cost} to become a Pro member",
      )
      expect(page).to have_link("Purchase credits", href: "/credits/purchase")
      expect(page).to have_link("Pro Membership page", href: "/pro")
    end

    it "contains the correct info if you have enough credits" do
      create_list(:credit, cost, user: user)

      visit "/settings/pro-membership"
      expect(page).to have_content("Pro Membership is #{cost} credits per month")
      expect(page).to have_content("You currently have #{user.credits.unspent.size} available credits")
      expect(page).not_to have_link("Purchase credits", href: "/credits/purchase")
      expect(page).to have_selector("input[type=submit][value='Become a Pro member']")
      expect(page).to have_link("Pro Membership page", href: "/pro")
    end
  end

  context "when signed in as as user with a pro role" do
    before do
      user.add_role(:pro)
      sign_in user
    end

    it "shows the status of the membership", js: true, percy: true do
      visit "/settings/pro-membership"

      Percy.snapshot(page, name: "Settings: /settings/pro-membership renders for pro role")

      expect(page).to have_content("Status")
      expect(page).to have_content("Expiration date")
      expect(page).to have_content("Never")
      expect(page).to have_link("Pro Membership page", href: "/pro")
    end
  end

  context "when signed in as as user with a pro membership" do
    before do
      create(:pro_membership, user: user, expires_at: 1.month.from_now)
      sign_in user
    end

    it "shows the status of the membership", js: true, percy: true do
      visit "/settings/pro-membership"

      Percy.snapshot(page, name: "Settings: /settings/pro-membership renders for pro membership")

      expect(page).to have_content("Status")
      expect(page).to have_content("Expiration date")
      expect(page).to have_content(user.pro_membership.expires_at.to_date.to_s(:long))
      expect(page).to have_content("Top up from credit card?")
      expect(page).to have_selector("input[type=submit]")
      expect(page).to have_link("Pro Membership page", href: "/pro")
    end

    it "updates the auto recharge" do
      visit "/settings/pro-membership"

      check "pro_membership[auto_recharge]"
      click_on "SUBMIT"
      expect(page).to have_content("Your membership has been updated!")
    end
  end
end
