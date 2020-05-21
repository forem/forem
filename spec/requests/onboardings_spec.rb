require "rails_helper"

RSpec.describe "Onboardings", type: :request do
  let(:user) { create(:user, saw_onboarding: false) }

  describe "GET /onboarding" do
    it "redirects user if unauthenticated" do
      get onboarding_url
      expect(response).to redirect_to("/enter")
    end

    it "return 200 when authentidated" do
      sign_in user
      get onboarding_url
      expect(response).to have_http_status(:ok)
    end
  end
end
