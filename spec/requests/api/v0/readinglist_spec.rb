require "rails_helper"

RSpec.describe "Api::V0::ReadingList", type: :request do
  describe "GET /api/readinglist" do
    let(:readinglist) { create_list(:reading_reaction, 3, user: user) }

    context "when request is unauthenticated" do
      it "return unauthorized" do
        get api_readinglist_index_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      let(:access_token) { create :doorkeeper_access_token, resource_owner: user, scopes: "public read_articles" }
      let(:user) { create(:user) }

      it "works with bearer authorization" do
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        get api_readinglist_index_path, headers: headers
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns proper response specification" do
        get api_readinglist_index_path, params: { access_token: access_token.token }
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "doesn't return archived reactions" do
        create(:reading_reaction, user: user)
        create(:reading_reaction, user: user, status: :archived)
        get api_readinglist_index_path, params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(1)
      end

      it "supports pagination" do
        create_list(:reading_reaction, 3, user: user)
        get api_readinglist_index_path, params: { access_token: access_token.token, page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end
    end
  end
end
