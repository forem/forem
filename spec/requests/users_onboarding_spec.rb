require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  let!(:user) do
    create(:user,
           saw_onboarding: false,
           _skip_creating_profile: true,
           profile: create(:profile, location: "Llama Town"))
  end

  describe "PATCH /onboarding_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding_update.json", params: {}
        expect(user.saw_onboarding).to eq(true)
      end

      it "updates the user's last_onboarding_page attribute" do
        params = { user: { last_onboarding_page: "v2: personal info form", username: "test" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.to change(user, :last_onboarding_page)
      end

      it "updates the user's username attribute" do
        params = { user: { username: "WilhuffTarkin" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.to change(user, :username).to("wilhufftarkin")
      end

      it "returns a 422 error if the username is blank" do
        params = { user: { username: "" } }
        patch "/onboarding_update.json", params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "updates the user's profile" do
        params = { profile: { location: "Galactic Empire" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.to change(user.profile, :location).to("Galactic Empire")
      end

      it "does not update the user's last_onboarding_page if it is empty" do
        params = { user: { last_onboarding_page: "" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.not_to change(user, :last_onboarding_page)
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
