require "rails_helper"

RSpec.describe "Stories::Feeds", type: :request do
  let(:title) { "My post" }
  let(:user) { create(:user, name: "Josh") }
  let(:organization) { create(:organization, name: "JoshCo") }
  let(:tags) { "alpha, beta, delta, gamma" }
  let(:article) { create(:article, title: title, featured: true, user: user, organization: organization, tags: tags) }

  before do
    article
  end

  describe "GET feeds show" do
    let(:response_json) { JSON.parse(response.body) }
    let(:response_article) { response_json.first }

    it "renders article list as json" do
      get "/stories/feed", headers: headers

      expect(response.media_type).to eq("application/json")
      expect(response_article).to include(
        "id" => article.id,
        "title" => title,
        "user_id" => user.id,
        "user" => hash_including("name" => user.name),
        "organization_id" => organization.id,
        "organization" => hash_including("name" => organization.name),
        "tag_list" => article.decorate.cached_tag_list_array,
      )
    end

    it "returns feed when feed_strategy is basic" do
      allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
      get "/stories/feed"
      expect(response_article).to include(
        "id" => article.id,
        "title" => title,
        "user_id" => user.id,
        "user" => hash_including("name" => user.name),
        "organization_id" => organization.id,
        "organization" => hash_including("name" => organization.name),
        "tag_list" => article.decorate.cached_tag_list_array,
      )
    end

    it "returns feed when feed_strategy is optimized" do
      allow(Settings::UserExperience).to receive(:feed_strategy).and_return("optimized")
      get "/stories/feed"
      expect(response_article).to include(
        "id" => article.id,
        "title" => title,
        "user_id" => user.id,
        "user" => hash_including("name" => user.name),
        "organization_id" => organization.id,
        "organization" => hash_including("name" => organization.name),
        "tag_list" => article.decorate.cached_tag_list_array,
      )
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
      let(:feed_service) { Articles::Feeds::LargeForemExperimental.new(number_of_articles: 1, page: 1, tag: []) }

      it "calls the feed service for a timeframe" do
        allow(Articles::Feeds::LargeForemExperimental).to receive(:new).and_return(feed_service)
        allow(feed_service).to receive(:top_articles_by_timeframe).with(timeframe: "week").and_call_original
        get "/stories/feed/week", headers: headers
        expect(feed_service).to have_received(:top_articles_by_timeframe).with(timeframe: "week")
      end

      it "calls the feed service for latest" do
        allow(Articles::Feeds::LargeForemExperimental).to receive(:new).and_return(feed_service)
        allow(feed_service).to receive(:latest_feed).and_call_original
        get "/stories/feed/latest", headers: headers
        expect(feed_service).to have_received(:latest_feed)
      end
    end

    context "when there are no params passed (base feed) and user is signed in" do
      before do
        sign_in user
      end

      it "returns feed when feed_strategy is basic" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
        get "/stories/feed"
        expect(response_article).to include(
          "id" => article.id,
          "title" => title,
          "user_id" => user.id,
          "user" => hash_including("name" => user.name),
          "organization_id" => organization.id,
          "organization" => hash_including("name" => organization.name),
          "tag_list" => article.decorate.cached_tag_list_array,
        )
      end

      it "returns feed when feed_strategy is optimized" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("optimized")
        get "/stories/feed"
        expect(response_article).to include(
          "id" => article.id,
          "title" => title,
          "user_id" => user.id,
          "user" => hash_including("name" => user.name),
          "organization_id" => organization.id,
          "organization" => hash_including("name" => organization.name),
          "tag_list" => article.decorate.cached_tag_list_array,
        )
      end
    end

    context "when there are no params passed (base feed) and user is not signed in" do
      it "does not set a field test" do
        expect do
          get "/stories/feed"
        end.not_to change(FieldTest::Membership, :count)
      end
    end

    context "when there are highly rated comments" do
      let(:comment) { create(:comment, score: 20, user: user) }
      let(:article) { comment.commentable }

      it "renders top comments for the article" do
        get "/stories/feed/infinity", headers: headers

        expect(response_article["top_comments"]).not_to be_nil
        expect(response_article["top_comments"].first["username"]).not_to be_nil
      end
    end
  end
end
