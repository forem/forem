require "rails_helper"

RSpec.describe "Api::V0::ReadingList" do
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "api-key" => api_secret.secret } }

  describe "GET /api/readinglist" do
    let(:readinglist) { create_list(:reading_reaction, 3, user: user) }

    context "when request is unauthenticated" do
      it "return unauthorized" do
        get api_readinglist_index_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      let(:user) { create(:user) }

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
    end
  end
end
