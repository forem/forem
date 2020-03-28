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
    let(:mock_documents) do
      [{ "title" => "classified_listing1" }]
    end

    it "returns json" do
      allow(Search::ClassifiedListing).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/classified_listings"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end
  end

  describe "GET /search/users" do
    let(:mock_documents) { [{ "username" => "firstlast" }] }

    it "returns json" do
      allow(Search::User).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/users"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end
  end

  describe "GET /search/feed_content" do
    let(:mock_documents) { [{ "title" => "article1" }] }

    it "returns json" do
      allow(Search::FeedContent).to receive(:search_documents).and_return(
        mock_documents,
      )

      get "/search/feed_content"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end

    it "queries only the user index if class_name=User" do
      allow(Search::FeedContent).to receive(:search_documents)
      allow(Search::User).to receive(:search_documents).and_return(
        mock_documents,
      )

      get "/search/feed_content?class_name=User"
      expect(Search::User).to have_received(:search_documents)
      expect(Search::FeedContent).not_to have_received(:search_documents)
    end

    it "queries for Articles, Podcast Episodes and Users if no class_name filter is present" do
      allow(Search::FeedContent).to receive(:search_documents).and_return(
        mock_documents,
      )
      allow(Search::User).to receive(:search_documents).and_return(
        mock_documents,
      )

      get "/search/feed_content"
      expect(Search::User).to have_received(:search_documents)
      expect(Search::FeedContent).to have_received(:search_documents)
    end

    it "queries for only Articles and Podcast Episodes if class_name!=User" do
      allow(Search::FeedContent).to receive(:search_documents).and_return(
        mock_documents,
      )
      allow(Search::User).to receive(:search_documents)

      get "/search/feed_content?class_name=Article"
      expect(Search::User).not_to have_received(:search_documents)
      expect(Search::FeedContent).to have_received(:search_documents)
    end
  end
end
