require "rails_helper"

RSpec.describe "Api::V0::FollowersController", type: :request do
  let(:follower) { create(:user) }

  describe "GET /api/followers/organizations" do
    context "when user is unauthorized" do
      it "returns unauthorized" do
        get api_followers_organizations_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      let(:orgs) { create_list(:organization, 2) }
      let(:user) { create(:user) }

      before do
        orgs.each { |org| follower.follow(org) }

        # add the user to each organization
        orgs.each do |org|
          create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        end

        sign_in user
      end

      it "returns all the followers of all organizations the user is part of" do
        get api_followers_organizations_path
        expect(response).to have_http_status(:ok)

        followers = response.parsed_body
        expect(followers.map { |f| f["id"] }).to match_array(follower.follows.pluck(:id))
        expect(followers.map { |f| f["organization_id"] }).to match_array(orgs.map(&:id))
      end

      it "returns the followers with the correct format" do
        get api_followers_organizations_path
        expect(response).to have_http_status(:ok)

        response_follower = response.parsed_body.first
        expect(response_follower["type_of"]).to eq("organization_follower")
        expect(response_follower["id"]).to eq(follower.follows.last.id)
        expect(response_follower["organization_id"]).to eq(follower.follows.last.followable.id)
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
