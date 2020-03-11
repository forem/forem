require "rails_helper"

RSpec.describe "Stories::FeedsIndex", type: :request do
  let(:title) { "My post" }
  let(:user) { create(:user, name: "Josh") }
  let(:organization) { create(:organization, name: "JoshCo") }
  let(:tags) { "alpha, beta, delta, gamma" }
  let(:article) { create(:article, title: title, featured: true, user: user, organization: organization, tags: tags) }

  before do
    article
  end

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

    context "when rendering an article with an image" do
      let(:cloud_cover) { CloudCoverUrl.new(article.main_image) }

      it "renders main_image as a cloud link" do
        allow(CloudCoverUrl).to receive(:new).with(article.main_image).and_return(cloud_cover)
        allow(cloud_cover).to receive(:call).and_call_original

        get "/stories/feed", headers: headers

        expect(CloudCoverUrl).to have_received(:new).with(article.main_image)
        expect(cloud_cover).to have_received(:call)
      end
    end

    context "when main_image is null" do
      let(:article) { create(:article, main_image: nil) }

      it "renders main_image as null" do
        # Calling the standard feed endpoint only retrieves articles without images if you're logged in.
        # We'll call use the 'latest' param to get around this
        get "/stories/feed?timeframe=latest", headers: headers
        expect(response_article["main_image"]).to eq nil
      end
    end

    context "when there isn't an organization attached to the article" do
      let(:organization) { nil }

      it "omits organization keys from json" do
        get "/stories/feed", headers: headers

        expect(response_article["organization_id"]).to eq nil
        expect(response_article["organization"]).to eq nil
      end
    end

    context "when there aren't any tags on the article" do
      let(:tags) { nil }

      it "renders an empty tag list" do
        get "/stories/feed", headers: headers

        expect(response_article["tag_list"]).to eq []
      end
    end

    context "when timeframe parameter is present" do
      let(:feed_service) { Articles::Feed.new(number_of_articles: 1, page: 1, tag: []) }

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

    context "when there are no params passed (base feed) and user is signed in" do
      before do
        sign_in user
      end

      it "sets a field test" do
        get "/stories/feed"
        expect(FieldTest::Membership.all.size).to be(1)
        expect(FieldTest::Membership.last.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Membership.last.experiment).to eq("user_home_feed")
      end
    end

    context "when there are no params passed (base feed) and user is signed not in" do
      it "sets a field test" do
        get "/stories/feed"
        expect(FieldTest::Membership.all.size).to be(0)
      end
    end
  end
end
