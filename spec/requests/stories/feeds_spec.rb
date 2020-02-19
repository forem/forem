require "rails_helper"

RSpec.describe "Stories::FeedsIndex", type: :request do
  let(:title) { "My post" }
  let(:user) { create(:user, name: "Josh") }
  let(:organization) { create(:organization, name: "JoshCo") }
  let!(:article) { create(:article, title: title, featured: true, user: user, organization: organization) }

  describe "GET feeds index" do
    let(:response_json) { JSON.parse(response.body) }
    let(:response_article) { response_json.first }

    it "renders article list as json" do
      get "/stories/feed", headers: headers

      expect(response.content_type).to eq("application/json")
      expect(response_article["id"]).to eq article.id
      expect(response_article["title"]).to eq title
      expect(response_article["user_id"]).to eq user.id
      expect(response_article["user"]["name"]).to eq user.name
      expect(response_article["organization_id"]).to eq organization.id
      expect(response_article["organization"]["name"]).to eq organization.name
      expect(response_article["tag_list"]).to eq article.decorate.cached_tag_list_array
    end

    context "when timeframe parameter is present" do
      let(:feed_service) {  Articles::Feed.new(number_of_articles: 1, page: 1, tag: []) }

      it "calls the feed service for a timeframe" do
        allow(Articles::Feed).to receive(:new).and_return(feed_service)
        allow(feed_service).to receive(:top_articles_by_timeframe).with(timeframe: "week").and_call_original
        get "/stories/feed/week", headers: headers
        expect(feed_service).to have_received(:top_articles_by_timeframe).with(timeframe: "week")
      end

      it "calls the feed service for latest" do
        allow(Articles::Feed).to receive(:new).and_return(feed_service)
        allow(feed_service).to receive(:latest_feed).and_call_original
        get "/stories/feed/latest", headers: headers
        expect(feed_service).to have_received(:latest_feed)
      end
    end
  end
end
