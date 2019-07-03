require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  let(:user) { create(:user, saw_onboarding: false) }

  before do
    sign_in user
  end

  describe "PATCH /onboarding_update" do
    it "updates saw_onboarding boolean" do
      patch "/onboarding_update.json", params: {}
      expect(user.saw_onboarding).to eq(true)
    end
  end
end
