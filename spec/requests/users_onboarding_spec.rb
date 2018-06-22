require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  before do
    @user = create(:user, saw_onboarding: false)
    login_as @user
  end

  describe "PATCH /onboarding_update" do
    it "updates saw_onboarding boolean" do
      patch "/onboarding_update.json", params: {}
      expect(@user.saw_onboarding).to eq(true)
    end
  end
end
