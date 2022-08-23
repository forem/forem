require "rails_helper"

RSpec.describe "Api::V1::ReadingList", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "api-key" => api_secret.secret, "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/readinglist" do
    let(:readinglist) { create_list(:reading_reaction, 3, user: user) }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_readinglist_index_path, headers: { "Accept" => "application/vnd.forem.api-v1+json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized" do
        get api_readinglist_index_path, headers: headers.merge({ "api-key" => "invalid api key" })
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      it "returns proper response specification" do
        get api_readinglist_index_path, headers: headers
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "doesn't return archived reactions" do
        create(:reading_reaction, user: user)
        create(:reading_reaction, user: user, status: :archived)
        get api_readinglist_index_path, headers: headers
        expect(response.parsed_body.length).to eq(1)
      end

      it "supports pagination" do
        create_list(:reading_reaction, 3, user: user)
        get api_readinglist_index_path, headers: headers, params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "doesn't return reading list items from other users" do
        create_list(:reading_reaction, 3, user: user)
        create_list(:reading_reaction, 2, user: user2)
        get api_readinglist_index_path, headers: headers
        expect(response.parsed_body.length).to eq(3)
      end
    end
  end
end
