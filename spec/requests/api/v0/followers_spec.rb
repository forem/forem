require "rails_helper"

RSpec.describe "Api::V0::FollowersController", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe "GET /api/followers" do
    before do
      sign_in user
      user2.follow user
      user.reload
      get "/api/followers"
    end

    it "returns followers list" do
      expect(response.body).to include user2.name
    end
  end
end
