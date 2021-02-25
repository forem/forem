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

  describe "GET /search/listings" do
    let(:mock_documents) do
      [{ "title" => "listing1" }]
    end

    it "returns json" do
      allow(Search::Listing).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/listings"
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

  describe "GET /search/usernames" do
    let(:authorized_user) { create(:user) }
    let(:result) do
      {
        "username" => "molly",
        "name" => "Molly",
        "profile_image_90" => "something"
      }
    end

    it "returns json" do
      sign_in authorized_user
      allow(Search::User).to receive(:search_usernames).and_return(
        result,
      )
      get "/search/usernames"
      expect(response.parsed_body).to eq("result" => result)
    end
  end

  describe "GET /search/feed_content" do
    let(:mock_documents) { [{ "title" => "article1" }] }

    it "returns json" do
      allow(Search::FeedContent).to receive(:search_documents).and_return(
        mock_documents,
      )

      get "/search/feed_content"
      expect(response.parsed_body["result"]).to eq(mock_documents)
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

    it "queries for approved" do
      allow(Search::FeedContent).to receive(:search_documents).and_return(
        mock_documents,
      )

      get "/search/feed_content?class_name=Article&approved=true"
      expect(Search::FeedContent).to have_received(:search_documents).with(
        params: { "approved" => "true", "class_name" => "Article" },
      )
    end
  end

  describe "GET /search/reactions" do
    let(:authorized_user) { create(:user) }
    let(:mock_response) do
      { "reactions" => [{ id: 123 }], "total" => 100 }
    end

    it "returns json with reactions and total" do
      sign_in authorized_user
      allow(Search::ReadingList).to receive(:search_documents).and_return(
        mock_response,
      )
      get "/search/reactions"
      expect(response.parsed_body).to eq("result" => [{ "id" => 123 }], "total" => 100)
    end

    it "accepts array of tag names" do
      sign_in authorized_user
      allow(Search::ReadingList).to receive(:search_documents).and_return(
        mock_response,
      )
      get "/search/reactions?tag_names[]=1&tag_names[]=2"
      expect(Search::ReadingList).to have_received(
        :search_documents,
      ).with(params: { "tag_names" => %w[1 2] }, user: authorized_user)
    end
  end
end
