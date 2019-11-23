require "rails_helper"

RSpec.describe "Api::V0::FollowingsController", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe "GET /api/followings" do
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
      get "/api/followings/users"
      expect(response.body).to include user2.name
    end

    it "returns following tag list" do
      get "/api/followings/tags"
      expect(response.body).to include tag.name
    end

    it "returns following organization list" do
      get "/api/followings/organizations"
      expect(response.body).to include organization.name
    end

    it "returns following podcast list" do
      get "/api/followings/podcasts"
      expect(response.body).to include podcast.name
    end
  end
end
