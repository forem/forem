require "rails_helper"

RSpec.describe "Api::V0::FollowersController", type: :request do
  let(:follower) { create(:user) }

  describe "GET /api/followers/organizations" do
    let(:org) { create(:organization) }
    let(:user) { create(:user, organization_id: org.id) }

    before do
      follower.follow(org)

      org.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get api_followers_organizations_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followers list with the correct format" do
        get api_followers_organizations_path
        expect(response).to have_http_status(:ok)

        response_follower = response.parsed_body.first
        expect(response_follower["type_of"]).to eq("organization_follower")
        expect(response_follower["id"]).to eq(follower.follows.last.id)
        expect(response_follower["name"]).to eq(follower.name)
        expect(response_follower["path"]).to eq(follower.path)
        expect(response_follower["username"]).to eq(follower.username)
        expect(response_follower["profile_image"]).to eq(ProfileImage.new(follower).get(width: 60))
      end
    end
  end

  describe "GET /api/followers/users" do
    let(:user) { create(:user) }

    before do
      follower.follow(user)

      user.reload
    end

    context "when user is unauthorized" do
      it "returns unauthorized" do
        get api_followers_users_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before do
        sign_in user
      end

      it "returns user's followers list with the correct format" do
        get api_followers_users_path
        expect(response).to have_http_status(:ok)

        response_follower = response.parsed_body.first
        expect(response_follower["type_of"]).to eq("user_follower")
        expect(response_follower["id"]).to eq(follower.follows.last.id)
        expect(response_follower["name"]).to eq(follower.name)
        expect(response_follower["path"]).to eq(follower.path)
        expect(response_follower["username"]).to eq(follower.username)
        expect(response_follower["profile_image"]).to eq(ProfileImage.new(follower).get(width: 60))
      end
    end
  end
end
