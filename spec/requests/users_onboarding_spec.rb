require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  let(:user) { create(:user, saw_onboarding: false) }

  describe "PATCH /onboarding_update" do
    it "updates saw_onboarding boolean" do
      sign_in user
      patch "/onboarding_update.json", params: {}
      expect(user.saw_onboarding).to eq(true)
    end

    it "returns a not found error if user is not signed in" do
      patch "/onboarding_update.json", params: {}
      expect(response.parsed_body["error"]).to include("Please sign in")
    end
  end

  describe "PATCH /onboarding_checkbox_update" do
    it "updates saw_onboarding boolean" do
      sign_in user
      patch "/onboarding_checkbox_update.json", params: {}
      expect(user.saw_onboarding).to eq(true)
    end

    it "returns a not found error if user is not signed in" do
      patch "/onboarding_checkbox_update.json", params: {}
      expect(response.parsed_body["error"]).to include("Please sign in")
    end
  end
end
