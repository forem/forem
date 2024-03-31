require "rails_helper"

RSpec.describe "Completing Onboarding", js: true do
  let(:password) { Faker::Internet.password(min_length: 8) }
  let(:user) { create(:user, password: password, password_confirmation: password, saw_onboarding: false) }

  after do
    sign_out user
  end

  # rubocop:disable RSpec/PendingWithoutReason
  context "when the user hasn't seen onboarding" do
    xit "does not render the onboarding task card on the feed" do
      sign_in(user)
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

    xit "renders the feed and onboarding task card" do
      visit "/"

      wait_for_javascript
      expect(page).to have_css(".onboarding-task-card")
    end

    it "shows a call to action for creating a post and can dismiss the onboarding task card", :aggregate_failures do
      visit "/"

      wait_for_javascript
      # A two-for one test: do we have the onboarding-task-card AND does it have the call to action
      # of creating a post
      expect(page).to have_css(".onboarding-task-card .task-card-action.js-policy-article-create")

      find(".onboarding-task-card .close").click
      expect(page).not_to have_css(".onboarding-task-card")
    end
  end

  context "when site limits article creation to admins" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:limit_post_creation_to_admins).and_return(true)
      user.update(saw_onboarding: true)

      visit sign_up_path
      log_in_user(user)
    end

    context "when user is admin", :aggregate_failures do
      let(:user) { create(:user, :admin, password: password, password_confirmation: password) }

      it "renders the feed and onboarding task card", :aggregate_failures do
        visit "/"

        wait_for_javascript
        expect(page).to have_css(".onboarding-task-card")
        expect(page).to have_css(".onboarding-task-card .task-card-action.js-policy-article-create")
      end
    end

    context "when user is not an admin", :aggregate_failures do
      let(:user) { create(:user, password: password, password_confirmation: password) }

      it "does not render a Create a Post call to action in the onboarding task card", :aggregate_failures do
        visit "/"

        wait_for_javascript
        expect(page).to have_css(".onboarding-task-card")
        expect(page).not_to have_css(".onboarding-task-card .task-card-action.js-policy-article-create")
      end
    end
  end
  # rubocop:enable RSpec/PendingWithoutReason

  # TODO: Extract this into a reusable helper
  def log_in_user(user)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: user.password)
    click_button("Log in", match: :first)
  end
end
