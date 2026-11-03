require "rails_helper"

RSpec.describe "Completing Onboarding", :js do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
  end

  context "when the user has seen onboarding" do
    it "shows a call to action for creating a post and can dismiss the onboarding task card", :aggregate_failures do
      visit "/"

      wait_for_javascript
      expect(page).to have_css(".onboarding-task-card .task-card-action.js-policy-article-create")

      find(".onboarding-task-card .close").click
      expect(page).to have_no_css(".onboarding-task-card")
    end
  end

  context "when site limits article creation to admins and user is not an admin" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:limit_post_creation_to_admins).and_return(true)
    end

    it "does not render a Create a Post call to action in the onboarding task card", :aggregate_failures do
      visit "/"

      wait_for_javascript
      expect(page).to have_css(".onboarding-task-card")
      expect(page).to have_no_css(".onboarding-task-card .task-card-action.js-policy-article-create")
    end
  end
end
