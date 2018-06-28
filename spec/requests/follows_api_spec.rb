require "rails_helper"

RSpec.describe "FollowsApi", type: :request do
  describe "POST /api/follows" do
    let(:user) { create(:user) }
    let(:user_2) { create(:user) }
    let(:user_3) { create(:user) }
    let(:user_4) { create(:user) }
    let(:user_5) { create(:user) }
    it "returns empty if user not signed in" do
      users_hash = [{id: user_2.id}, {id: user_3.id}, {id: user_4.id}, {id: user_5.id}].to_json
      post "/api/follows", params: { users: users_hash }
      expect(response.body.size).to eq(0)
    end

    it "makes successful ping" do
      sign_in user
      users_hash = [{id: user_2.id}, {id: user_3.id}, {id: user_4.id}, {id: user_5.id}].to_json
      post "/api/follows", params: { users: users_hash }
      expect(response.body).to include("outcome")
    end
  end
end