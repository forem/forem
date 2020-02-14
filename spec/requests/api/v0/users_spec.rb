require "rails_helper"

RSpec.describe "Api::V0::Users", type: :request do
  describe "GET /api/users" do
    it "returns no users if state is not present" do
      get api_users_path

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body).to be_empty
    end

    it "returns users from the original core team if they are present" do
      user = create(:user, username: "ben", summary: "Something something")

      get api_users_path

      expect(response).to have_http_status(:ok)

      response_user = response.parsed_body.first
      expect(response_user["id"]).to eq(user.id)
      expect(response_user["name"]).to eq(user.name)
      expect(response_user["username"]).to eq(user.username)
      expect(response_user["summary"]).to eq(user.summary)
      expect(response_user["profile_image_url"]).to eq(ProfileImage.new(user).get(width: 90))
      expect(response_user["following"]).to be(false)
    end

    it "returns follow suggestions for an authenticated user" do
      user = create(:user)
      tag = create(:tag)
      user.follow(tag)

      other_user = create(:user)
      create(:article, user: other_user, tags: [tag.name])

      sign_in user

      get api_users_path(state: "follow_suggestions")

      response_user = response.parsed_body.first
      expect(response_user["id"]).to eq(other_user.id)
    end

    it "returns no sidebar suggestions for an authenticated user" do
      sign_in create(:user)

      get api_users_path(state: "sidebar_suggestions")

      expect(response.parsed_body).to be_empty
    end
  end

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

    it "returns 200 if the user username is found" do
      get api_user_path("by_username"), params: { url: user.username }
      expect(response).to have_http_status(:ok)
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
      expect(response_user["profile_image"]).to eq(ProfileImage.new(user).get(width: 320))
    end
  end

  describe "GET /api/users/me" do
    it "requires request to be authenticated" do
      get me_api_users_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "when request is authenticated" do
      let_it_be(:user)         { create(:user) }
      let_it_be(:access_token) { create(:doorkeeper_access_token, resource_owner: user, scopes: "public") }

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
        expect(response_user["profile_image"]).to eq(ProfileImage.new(user).get(width: 320))
      end
    end
  end
end
