require "rails_helper"

RSpec.describe "Api::V0::FollowersController", type: :request do
  let(:user) { create(:user) }
  let(:follower) { create(:user) }

  describe "GET /api/followers" do
    before do
      follower.follow user
      user.reload
    end

    context "when user is unauthorized" do
      it "does not return user followers list" do
        get users_api_followers_path
        expect(response.body).not_to include follower.name
      end
    end

    context "when user is authorized" do
      it "returns user followers list" do
        sign_in user
        get users_api_followers_path
        expect(response.body).to include follower.name
      end
    end
  end
end
