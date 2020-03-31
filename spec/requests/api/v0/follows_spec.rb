require "rails_helper"

RSpec.describe "Api::V0::FollowsController", type: :request do
  describe "POST /api/follows" do
    it "returns unauthorized if user is not signed in" do
      post "/api/follows", params: { users: [] }
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is authorized" do
      let_it_be(:user) { create(:user) }
      let_it_be(:users_hash) { [{ id: create(:user).id }, { id: create(:user).id }] }

      before do
        sign_in user
      end

      it "returns the number of followed users" do
        post "/api/follows", params: { users: users_hash }
        expect(response.parsed_body["outcome"]).to include("#{users_hash.size} users")
      end

      it "creates follows" do
        sign_in user
        expect do
          sidekiq_perform_enqueued_jobs do
            post "/api/follows", params: { users: users_hash }
          end
        end.to change(Follow, :count).by(users_hash.size)
      end
    end
  end
end
