require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users" do
    it "returns no users if state is not present" do
      get users_path

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body).to be_empty
    end

    it "returns users from the original core team if they are present" do
      user = create(:user, username: "ben", summary: "Something something")

      get users_path

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

      get users_path(state: "follow_suggestions")

      response_user = response.parsed_body.first
      expect(response_user["id"]).to eq(other_user.id)
    end

    it "returns follow suggestions that have profile images" do
      user = create(:user)
      tag = create(:tag)
      user.follow(tag)

      other_user = create(:user)
      create(:article, user: other_user, tags: [tag.name])

      sign_in user

      get users_path(state: "follow_suggestions")

      response_user = response.parsed_body.first
      expect(response_user["profile_image_url"]).to eq(other_user.profile_image_url)
    end

    it "returns no sidebar suggestions for an authenticated user" do
      sign_in create(:user)

      get users_path(state: "sidebar_suggestions")

      expect(response.parsed_body).to be_empty
    end
  end
end
