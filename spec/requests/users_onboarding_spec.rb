require "rails_helper"

RSpec.describe "UsersOnboarding" do
  let!(:user) do
    create(:user,
           saw_onboarding: false,
           _skip_creating_profile: true,
           profile: create(:profile, location: "Llama Town"))
  end

  describe "PATCH /onboarding_checkbox_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding_checkbox_update.json", params: {}
        expect(user.saw_onboarding).to be(true)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding_checkbox_update.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end
end
