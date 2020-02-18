require "rails_helper"

RSpec.describe "Stories::FeedsIndex", type: :request do
  let(:title) { "My post" }
  let!(:article) { create(:article, title: title, featured: true) }

  describe "GET feeds index" do
    let(:response_json) { JSON.parse(response.body) }
    let(:response_article) { response_json.first }

    it "renders article list as json" do
      get "/stories/feed", headers: headers
      expect(response.content_type).to eq("application/json")
      expect(response.body).to include(article.id.to_s)
      expect(response_article["title"]).to eq title
      expect(response_article["class_name"]).to eq "Article"
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
