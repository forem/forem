require "rails_helper"

RSpec.describe "Api::V0::Users", type: :request do
  describe "GET /api/users/:id" do
    let(:user) { create(:user, summary: "Something something", profile_image: "") }

    it "returns 404 if the user id is not found" do
      get api_user_path("invalid-id")

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the user username is not found" do
      get api_user_path("by_username"), params: { url: "invalid-username" }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the user is not registered" do
      user.update_column(:registered, false)
      get api_user_path(user.id)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 200 if the user username is found" do
      get api_user_path("by_username"), params: { url: user.username }
      expect(response).to have_http_status(:ok)
    end

    it "returns unauthenticated if no authentication and site config is set to private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      get api_user_path("by_username"), params: { url: user.username }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the correct json representation of the user", :aggregate_failures do
      get api_user_path(user.id)

      response_user = response.parsed_body

      expect(response_user["type_of"]).to eq("user")

      %w[
        id username name summary twitter_username github_username website_url location
      ].each do |attr|
        expect(response_user[attr]).to eq(user.public_send(attr))
      end

      expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
      expect(response_user["profile_image"]).to eq(Images::Profile.call(user.profile_image_url, length: 320))
    end
  end

  describe "GET /api/users/me" do
    it "requires request to be authenticated" do
      get me_api_users_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "when request is authenticated" do
      let(:user)         { create(:user) }
      let(:access_token) { create(:doorkeeper_access_token, resource_owner: user, scopes: "public") }

      it "returns the correct json representation of the user", :aggregate_failures do
        get me_api_users_path, params: { access_token: access_token.token }

        response_user = response.parsed_body

        expect(response_user["type_of"]).to eq("user")

        %w[
          id username name summary twitter_username github_username website_url location
        ].each do |attr|
          expect(response_user[attr]).to eq(user.public_send(attr))
        end

        expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
        expect(response_user["profile_image"]).to eq(Images::Profile.call(user.profile_image_url, length: 320))
      end

      it "returns 200 if no authentication and site config is set to private but user is authenticated" do
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get me_api_users_path, params: { access_token: access_token.token }

        response_user = response.parsed_body

        expect(response_user["type_of"]).to eq("user")

        %w[
          id username name summary twitter_username github_username website_url location
        ].each do |attr|
          expect(response_user[attr]).to eq(user.public_send(attr))
        end

        expect(response_user["joined_at"]).to eq(user.created_at.strftime("%b %e, %Y"))
        expect(response_user["profile_image"]).to eq(Images::Profile.call(user.profile_image_url, length: 320))
      end
    end
  end
end
