require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  let(:user) { create(:user, saw_onboarding: false, location: "Llama Town") }

  describe "PATCH /onboarding_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        sign_in user
        patch "/onboarding_update.json", params: {}
        expect(user.saw_onboarding).to eq(true)
      end

      it "updates the attributes on the user" do
        params = { user: { location: "Alpaca Town" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.to change(user, :location)
      end

      it "does not update attributes if params are empty" do
        params = { user: { location: "" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.not_to change(user, :location)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding_update.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end

  describe "PATCH /onboarding_checkbox_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding_checkbox_update.json", params: {}
        expect(user.saw_onboarding).to eq(true)
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
