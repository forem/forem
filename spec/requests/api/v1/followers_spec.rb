require "rails_helper"

RSpec.describe "Api::V1::FollowersController", type: :request do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "api-key" => api_secret.secret, "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:follower) { create(:user) }
  let(:follower2) { create(:user) }

  before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

  describe "GET /api/followers/users" do
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

    context "when the user is authorized as current_user" do
      it "returns ok" do
        sign_in user

        get api_followers_users_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is authorized with api key" do
      it "returns user's followers list with the correct format" do
        get api_followers_users_path, headers: headers
        expect(response).to have_http_status(:ok)

        response_follower = response.parsed_body.first
        expect(response_follower["type_of"]).to eq("user_follower")
        expect(response_follower["id"]).to eq(follower.follows.last.id)
        expect(response_follower["name"]).to eq(follower.name)
        expect(response_follower["path"]).to eq(follower.path)
        expect(response_follower["username"]).to eq(follower.username)
        expect(response_follower["profile_image"]).to eq(follower.profile_image_url_for(length: 60))
        expect(response_follower["created_at"]).to be_an_instance_of(String)
      end

      it "supports pagination" do
        follower2.follow(user)

        get api_followers_users_path, params: { page: 1, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(1)

        get api_followers_users_path, params: { page: 2, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(1)

        get api_followers_users_path, params: { page: 3, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(0)
      end

      it "orders results by descending following date by default" do
        follower2.follow(user)

        get api_followers_users_path, headers: headers

        follows = user.followings.order(id: :desc).last(2).map(&:id)
        result = response.parsed_body.map { |f| f["id"] }
        expect(result).to eq(follows)
      end

      it "orders results by ascending following date if the 'sort' param is specified" do
        follower2.follow(user)

        follows = user.followings.order(id: :asc).last(2).map(&:id)
        get api_followers_users_path, headers: headers, params: { sort: "created_at" }
        result = response.parsed_body.map { |f| f["id"] }
        expect(result).to eq(follows)
      end
    end
  end
end
