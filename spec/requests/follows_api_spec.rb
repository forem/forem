require "rails_helper"

RSpec.describe "FollowsApi", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:user4) { create(:user) }
  let(:user5) { create(:user) }
  let(:users_hash) do
    [{ id: user2.id }, { id: user3.id }, { id: user4.id }, { id: user5.id }]
  end

  describe "POST /api/follows" do
    it "returns empty if user not signed in" do
      post "/api/follows", params: { users: users_hash }
      expect(response.body.size).to eq(0)
    end

    it "makes successful ping" do
      sign_in user
      post "/api/follows", params: { users: users_hash }
      expect(response.body).to include("outcome")
    end

    it "creates follows" do
      sign_in user
      perform_enqueued_jobs do
        post "/api/follows", params: { users: users_hash }
      end
      expect(Follow.all.size).to eq(users_hash.size)
    end
  end

  describe "GET /api/follows/followers" do
    before do
      sign_in user
      user2.follow user
      user.reload
      get "/api/follows/followers"
    end

    it "returns followers list" do
      expect(response.body).to include user2.name
    end
  end

  describe "GET /api/follows/following" do
    let(:tag) { create(:tag) }
    let(:podcast) { create(:podcast) }
    let(:organization) { create(:organization) }

    before do
      sign_in user
      user.follow user2
      user.follow tag
      user.follow organization
      user.follow podcast
      user.reload
    end

    it "returns following users list" do
      get "/api/follows/following_users"
      expect(response.body).to include user2.name
    end

    it "returns following tag list" do
      get "/api/follows/following_tags"
      expect(response.body).to include tag.name
    end

    it "returns following organization list" do
      get "/api/follows/following_organizations"
      expect(response.body).to include organization.name
    end

    it "returns following podcast list" do
      get "/api/follows/following_podcasts"
      expect(response.body).to include podcast.name
    end
  end
end
