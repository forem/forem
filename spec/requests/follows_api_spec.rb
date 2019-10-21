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
    it "returns unauthorized if user not signed in" do
      post "/api/follows", params: { users: users_hash }
      expect(response).to have_http_status(:unauthorized)
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
end
