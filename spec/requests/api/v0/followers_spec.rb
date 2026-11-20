require "rails_helper"

RSpec.describe "Api::V0::FollowersController" do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "api-key" => api_secret.secret } }
  let(:follower) { create(:user) }
  let(:follower2) { create(:user) }

  describe "GET /api/followers/users" do
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
      before do
        follower.follow(user)
        user.reload
      end

      it "returns user's followers list with the correct format", :aggregate_failures do
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

      it "supports pagination and descending order by default", :aggregate_failures do
        follower2.follow(user)

        get api_followers_users_path, headers: headers
        follows = user.followings.order(id: :desc).last(2).map(&:id)
        expect(response.parsed_body.pluck("id")).to eq(follows)

        get api_followers_users_path, params: { page: 1, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(1)

        get api_followers_users_path, params: { page: 2, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(1)

        get api_followers_users_path, params: { page: 3, per_page: 1 }, headers: headers
        expect(response.parsed_body.length).to eq(0)
      end

      it "orders results by ascending following date if the 'sort' param is specified" do
        follower2.follow(user)

        follows = user.followings.order(id: :asc).last(2).map(&:id)
        get api_followers_users_path, headers: headers, params: { sort: "created_at" }
        result = response.parsed_body.pluck("id")
        expect(result).to eq(follows)
      end

      it "filters by blocked = false to align with the composite followable_blocked_and_created_at index",
         :aggregate_failures do
        blocked_follower = create(:user)
        create(:follow, follower: blocked_follower, followable: user, blocked: true)

        follows_queries = []
        callback = lambda do |*, payload|
          sql = payload[:sql]
          follows_queries << sql if sql.include?('FROM "follows"') && payload[:name] != "SCHEMA"
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get api_followers_users_path, headers: headers
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("user_id")).to eq([follower.id])
        expect(follows_queries.size).to eq(1)
        expect(follows_queries.first).to match(/"follows"\."blocked" = (FALSE|\$\d+)/)
      end
    end
  end
end
