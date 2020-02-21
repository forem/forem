require "rails_helper"

RSpec.describe "Search", type: :request, proper_status: true do
  describe "GET /search/tags" do
    let(:authorized_user) { create(:user) }
    let(:mock_documents) do
      [{ "name" => "tag1" }, { "name" => "tag2" }, { "name" => "tag3" }]
    end

    it "returns json" do
      sign_in authorized_user
      allow(Search::Tag).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/tags"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end

    it "returns an empty array when a Bad Request error is raised" do
      sign_in authorized_user
      allow(SearchClient).to receive(:search).and_raise(Search::Errors::Transport::BadRequest)
      get "/search/tags"
      expect(response.parsed_body).to eq("result" => [])
    end
  end
end
