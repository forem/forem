require "rails_helper"

RSpec.describe "Completing Onboarding", type: :system, js: true do
  let(:password) { Faker::Internet.password(min_length: 8) }
  let(:user) { create(:user, password: password, password_confirmation: password, saw_onboarding: false) }

  after do
    sign_out user
  end

  context "when the user hasn't seen onboarding" do
    before do
      visit sign_up_path
      log_in_user(user)
    end

    xit "logs in and redirects to onboarding if it hasn't been seen" do
      expect(page).to have_current_path("/onboarding", ignore_query: true)
      expect(page.html).to include("onboarding-container")
    end

    xit "does not render the onboarding task card on the feed" do
      visit "/"

      # Explicitly test that the task card element HTML is not on the page.
      expect(page.html).not_to include("onboarding-task-card")
    end
  end

  context "when the user has seen onboarding" do
    before do
      user.update(saw_onboarding: true)

      visit sign_up_path
      log_in_user(user)
    end

    xit "logs in and renders the feed" do
      expect(page).to have_current_path("/?signin=true")
      expect(page.html).not_to include("onboarding-container")
    end

    it "renders the feed and onboarding task card" do
      visit "/"

      wait_for_javascript
      expect(page).to have_css(".onboarding-task-card")
    end

    it "can dismiss the onboarding task card" do
      visit "/"

      wait_for_javascript
      expect(page).to have_css(".onboarding-task-card")

      find(".onboarding-task-card .close").click
      expect(page).not_to have_css(".onboarding-task-card")
    end
  end

  # TODO: Vaidehi Joshi - Extract this into a reusable helper
  def log_in_user(user)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: user.password)
    click_button("Continue", match: :first)
  end
end
