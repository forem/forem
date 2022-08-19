require "rails_helper"

RSpec.describe "Api::V1::FollowsController", type: :request do

  before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

  describe "POST /api/follows" do
    it "returns unauthorized if user is not signed in" do
      post "/api/follows", params: { users: [] }
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is authorized" do
      let(:user) { create(:user) }
      let(:users_hash) { [{ id: create(:user).id }, { id: create(:user).id }] }

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

  describe "GET /api/follows/tags" do
    it "returns unauthorized if user is not signed in" do
      get "/api/follows/tags"
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is authorized" do
      let!(:user) { create(:user) }
      let(:tag1) { create(:tag) }
      let(:tag2) { create(:tag) }
      let(:tag3) { create(:tag) }

      let(:tag1_json) { { id: tag1.id, name: tag1.name, points: 1.0 } }
      let(:tag2_json) { { id: tag2.id, name: tag2.name, points: 1.0 } }

      before do
        sign_in user
        [tag1, tag2].each { |tag| user.follow(tag) }
      end

      it "returns only the tags the user follows", aggregate_failures: true do
        get "/api/follows/tags"
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body).to include(tag1_json)
        expect(body).to include(tag2_json)
      end
    end
  end
end
