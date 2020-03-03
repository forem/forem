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
      allow(Search::Client).to receive(:search).and_raise(Search::Errors::Transport::BadRequest)
      get "/search/tags"
      expect(response.parsed_body).to eq("result" => [])
    end
  end

  describe "GET /search/chat_channels" do
    let(:authorized_user) { create(:user) }
    let(:mock_documents) do
      [{ "channel_name" => "channel1" }]
    end

    it "returns json" do
      sign_in authorized_user
      allow(Search::ChatChannelMembership).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/chat_channels"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end
  end

  describe "GET /search/classified_listings" do
    let(:authorized_user) { create(:user) }
    let(:mock_documents) do
      [{ "title" => "classified_listing1" }]
    end

    it "returns json" do
      sign_in authorized_user
      allow(Search::ClassifiedListing).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/classified_listings"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end
  end
end
