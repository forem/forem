require "rails_helper"

RSpec.describe "Stories::Feeds" do
  let(:title) { "My post" }
  let(:user) { create(:user, name: "Josh") }
  let(:organization) { create(:organization, name: "JoshCo") }
  let(:tags) { "alpha, beta, delta, gamma" }
  let(:article) { create(:article, title: title, featured: true, user: user, organization: organization, tags: tags) }

  before do
    article
  end

  describe "GET feeds show" do
    let(:response_json) { response.parsed_body }
    let(:response_article) { response_json.first }

    it "renders article list as json" do
      get stories_feed_path

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

    context "when there are no params passed (base feed) and user is NOT signed in" do
      it "returns feed when feed_strategy is basic" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")

        get stories_feed_path

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

      it "returns feed when feed_strategy is large_forem_experimental" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("large_forem_experimental")

        get stories_feed_path

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

      it "returns feed when feed_strategy is configured" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("configured")

        get stories_feed_path

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

      it "sets cache control headers for edge caching" do
        get stories_feed_path

        expect(response.headers["Cache-Control"]).to eq("public, no-cache")
        expect(response.headers["X-Accel-Expires"]).to eq("60")
        expect(response.headers["Surrogate-Control"]).to include("max-age=60")
        expect(response.headers["Surrogate-Control"]).to include("stale-if-error=26400")
      end
    end

    context "when rendering an article that is pinned" do
      it "returns pinned set to true in the response" do
        PinnedArticle.set(article)

        get stories_feed_path

        pinned_item = response.parsed_body.detect { |item| item["pinned"] == true }
        expect(pinned_item["id"]).to eq(article.id)
      end

      it "returns pinned set to false in the response for non pinned articles" do
        get stories_feed_path

        pinned_item = response.parsed_body.detect { |item| item["pinned"] == true }
        expect(pinned_item).to be_nil
      end
    end

    context "when rendering an article with an image" do
      let(:cloud_cover) { CloudCoverUrl.new(article.main_image) }

      it "renders main_image as a cloud link" do
        allow(CloudCoverUrl).to receive(:new).with(article.main_image, nil).and_return(cloud_cover)
        allow(cloud_cover).to receive(:call).and_call_original

        get stories_feed_path

        expect(CloudCoverUrl).to have_received(:new).with(article.main_image, nil)
        expect(cloud_cover).to have_received(:call)
      end
    end

    context "when main_image is null" do
      let(:article) { create(:article, main_image: nil) }

      it "renders main_image as null" do
        # Calling the standard feed endpoint only retrieves articles without images if you're logged in.
        # We'll call use the 'latest' param to get around this
        get timeframe_stories_feed_path(:latest)
        expect(response_article["main_image"]).to be_nil
      end
    end

    context "when there isn't an organization attached to the article" do
      let(:organization) { nil }

      it "omits organization keys from json" do
        get stories_feed_path

        expect(response_article["organization_id"]).to be_nil
        expect(response_article["organization"]).to be_nil
      end
    end

    context "when there aren't any tags on the article" do
      let(:tags) { nil }

      it "renders an empty tag list" do
        get stories_feed_path

        expect(response_article["tag_list"]).to be_empty
      end
    end

    context "when timeframe parameter is present" do
      let(:feed_service) { Articles::Feeds::LargeForemExperimental.new(number_of_articles: 1, page: 1, tag: []) }

      it "calls the feed service for a timeframe" do
        allow(Articles::Feeds::LargeForemExperimental).to receive(:new).and_return(feed_service)
        allow(Articles::Feeds::Timeframe).to receive(:call).and_call_original

        get timeframe_stories_feed_path(:week)

        expect(Articles::Feeds::Timeframe).to have_received(:call).with("week", page: 1, tag: nil)
      end

      it "calls the feed service for latest" do
        allow(Articles::Feeds::LargeForemExperimental).to receive(:new).and_return(feed_service)
        allow(Articles::Feeds::Latest).to receive(:call).and_call_original

        get timeframe_stories_feed_path(:latest)

        expect(Articles::Feeds::Latest).to have_received(:call)
      end
    end

    context "when sign in is passed via token" do
      let(:user) { create(:user) }

      it "returns signed in feed" do
        payload = {
          user_id: user.id,
          exp: 5.minutes.from_now.to_i # Token expires in 5 minutes
        }
        token = JWT.encode(payload, Rails.application.secret_key_base)
        get stories_feed_path, headers: { "Authorization" => "Bearer #{token}" }

        expect(response_article).to include(
          "id" => article.id,
          "title" => title,
          "user_id" => user.id,
          "user" => hash_including("name" => user.name),
          "organization_id" => organization.id,
          "organization" => hash_including("name" => organization.name),
          "tag_list" => article.decorate.cached_tag_list_array,
          "current_user_signed_in" => true,
        )
      end

      it "does not set cache control headers for edge caching" do
        payload = {
          user_id: user.id,
          exp: 5.minutes.from_now.to_i # Token expires in 5 minutes
        }
        token = JWT.encode(payload, Rails.application.secret_key_base)
        get stories_feed_path, headers: { "Authorization" => "Bearer #{token}" }

        # Should not have the specific edge caching headers we set for signed out users
        expect(response.headers["X-Accel-Expires"]).to be_nil
        expect(response.headers["Surrogate-Control"]).to be_nil

        # Cache-Control might be set by other parts of the system, so we check it doesn't contain our specific values
        if response.headers["Cache-Control"]
          expect(response.headers["Cache-Control"]).not_to include("public, no-cache")
        end
      end
    end

    context "when there are no params passed (base feed) and user is signed in" do
      before do
        sign_in user
      end

      it "returns feed when feed_strategy is basic" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")

        get stories_feed_path

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

      it "returns feed when feed_strategy is large_forem_experimental" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("large_forem_experimental")

        get stories_feed_path

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

      it "does not set cache control headers for edge caching" do
        get stories_feed_path

        # Should not have the specific edge caching headers we set for signed out users
        expect(response.headers["X-Accel-Expires"]).to be_nil
        expect(response.headers["Surrogate-Control"]).to be_nil

        # Cache-Control might be set by other parts of the system, so we check it doesn't contain our specific values
        if response.headers["Cache-Control"]
          expect(response.headers["Cache-Control"]).not_to include("public, no-cache")
        end
      end
    end

    context "when there are highly rated comments" do
      let(:comment) { create(:comment, score: 20, user: user) }
      let(:article) { comment.commentable }

      it "renders top comments for the article" do
        get timeframe_stories_feed_path(:infinity)

        expect(response_article["top_comments"]).not_to be_nil
        expect(response_article["top_comments"].first["username"]).not_to be_nil
      end
    end

    context "when there are low-scoring articles" do
      let!(:article) { create(:article, featured: false) }

      it "excludes low-score article but not mid-score" do
        article_with_mid_score = create(:article, score: Settings::UserExperience.home_feed_minimum_score)
        article_with_low_score = create(:article, score: Articles::Feeds::Latest::MINIMUM_SCORE)

        get timeframe_stories_feed_path(:latest)

        response_array = response.parsed_body.pluck("title")
        expect(response_array).to contain_exactly(article.title, article_with_mid_score.title)
        expect(response_array).not_to include(article_with_low_score.title)
      end
    end

    context "when rendering quickie articles with line breaks" do
      let(:quickie_title) { "Line one\nLine two\n\nParagraph two\n\nParagraph three" }
      let(:quickie_article) do
        article = create(:article, type_of: "status", title: quickie_title, featured: true, body_markdown: "",
                                   main_image: nil)
        article.update!(published: true, title: quickie_title)
        article
      end

      before do
        quickie_article
      end

      it "includes title_finalized_for_feed in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("title_finalized_for_feed")
        expect(quickie_response["title_finalized_for_feed"]).to include("<br>")
        expect(quickie_response["title_finalized_for_feed"]).to include("quickie-paragraph")
      end

      it "includes title_for_metadata in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("title_for_metadata")
        expect(quickie_response["title_for_metadata"]).not_to include("\n")
        expect(quickie_response["title_for_metadata"]).to include("Line one Line two")
      end

      it "includes readable_publish_date in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("readable_publish_date")
        expect(quickie_response["readable_publish_date"]).to be_present
      end

      it "includes video_duration_in_minutes in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("video_duration_in_minutes")
      end

      it "includes flare_tag in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("flare_tag")
      end

      it "includes class_name in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("class_name")
        expect(quickie_response["class_name"]).to eq("Article")
      end

      it "includes cloudinary_video_url in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("cloudinary_video_url")
      end

      it "includes published_timestamp in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("published_timestamp")
      end

      it "includes main_image_background_hex_color in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("main_image_background_hex_color")
      end

      it "includes public_reaction_categories in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("public_reaction_categories")
      end

      it "includes body_preview in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("body_preview")
      end

      it "includes title_finalized in the response" do
        get stories_feed_path

        quickie_response = response.parsed_body.find { |item| item["id"] == quickie_article.id }
        expect(quickie_response).to include("title_finalized_for_feed")
        expect(quickie_response["title_finalized_for_feed"]).to include("<br>")
        expect(quickie_response["title_finalized_for_feed"]).to include("quickie-paragraph")
      end
    end

    context "when rendering long quickie articles (truncation test)" do
      let(:long_quickie_title) { "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10" }
      let(:long_quickie_article) do
        article = create(:article, type_of: "status", title: long_quickie_title, featured: true, body_markdown: "",
                                   main_image: nil)
        article.update!(published: true, title: long_quickie_title)
        article
      end

      before do
        long_quickie_article
      end

      it "truncates title_finalized_for_feed with read more indicator" do
        get stories_feed_path

        long_quickie_response = response.parsed_body.find { |item| item["id"] == long_quickie_article.id }
        expect(long_quickie_response).to include("title_finalized_for_feed")
        expect(long_quickie_response["title_finalized_for_feed"]).to include("quickie-read-more")
        expect(long_quickie_response["title_finalized_for_feed"]).to include("read more")
      end

      it "includes title_for_metadata without truncation" do
        get stories_feed_path

        long_quickie_response = response.parsed_body.find { |item| item["id"] == long_quickie_article.id }
        expect(long_quickie_response).to include("title_for_metadata")
        expect(long_quickie_response["title_for_metadata"]).not_to include("read more")
        expect(long_quickie_response["title_for_metadata"]).to include("Line 1 Line 2")
      end
    end

    context "when user is signed in and requests 'latest following' feed" do
      let(:followed_user) { create(:user) }
      let(:unfollowed_user) { create(:user) }
      let!(:followed_article) { create(:article, user: followed_user) }
      let!(:unfollowed_article) { create(:article, user: unfollowed_user) }

      before do
        sign_in user
        user.follow(followed_user)
      end

      it "returns articles from followed users only" do
        get stories_feed_path(type_of: "following", timeframe: "latest")

        response_article_ids = response.parsed_body.map { |a| a["id"] }
        expect(response_article_ids).to include(followed_article.id)
        expect(response_article_ids).not_to include(unfollowed_article.id)
      end

      it "returns empty array if no followed users have articles" do
        Article.delete_all
        get stories_feed_path(type_of: "following", timeframe: "latest")

        expect(response.parsed_body).to be_empty
      end

      it "does not return articles if user is not following anyone" do
        user.stop_following(followed_user)
        get stories_feed_path(type_of: "following", timeframe: "latest")

        expect(response.parsed_body).to be_empty
      end

      it "does not return articles from unfollowed users" do
        get stories_feed_path(type_of: "following", timeframe: "latest")

        response_article_ids = response.parsed_body.map { |a| a["id"] }
        expect(response_article_ids).not_to include(unfollowed_article.id)
      end
    end

    context "when user is not signed in and requests 'latest following' feed" do
      let(:followed_user) { create(:user) }
      let!(:followed_article) { create(:article, user: followed_user) }

      it "returns default latest feed" do
        get stories_feed_path(type_of: "following", timeframe: "latest")

        response_article_ids = response.parsed_body.map { |a| a["id"] }
        expect(response_article_ids).to include(article.id)
        expect(response_article_ids).to include(followed_article.id)
      end
    end

    context "when user is signed in and requests 'following' feed" do
      let(:followed_user) { create(:user) }
      let(:unfollowed_user) { create(:user) }
      let!(:followed_article) { create(:article, user: followed_user) }
      let!(:unfollowed_article) { create(:article, user: unfollowed_user) }

      before do
        sign_in user
        user.follow(followed_user)
      end

      context "and timeframe is not 'latest'" do
        it "returns articles from followed users only" do
          get stories_feed_path(type_of: "following")

          response_article_ids = response.parsed_body.map { |a| a["id"] }
          expect(response_article_ids).to include(followed_article.id)
          expect(response_article_ids).not_to include(unfollowed_article.id)
        end

        it "returns empty array if no followed users have articles" do
          Article.delete(followed_article.id)
          get stories_feed_path(type_of: "following")

          expect(response.parsed_body).to be_empty
        end

        it "does not return articles if user is not following anyone" do
          user.stop_following(followed_user)
          get stories_feed_path(type_of: "following")

          expect(response.parsed_body).to be_empty
        end

        it "does not return articles from unfollowed users" do
          get stories_feed_path(type_of: "following")

          response_article_ids = response.parsed_body.map { |a| a["id"] }
          expect(response_article_ids).not_to include(unfollowed_article.id)
        end
      end

      context "and timeframe is 'latest'" do
        it "returns articles from followed users only" do
          get stories_feed_path(type_of: "following", timeframe: "latest")

          response_article_ids = response.parsed_body.map { |a| a["id"] }
          expect(response_article_ids).to include(followed_article.id)
          expect(response_article_ids).not_to include(unfollowed_article.id)
        end
      end
    end

    context "when user is signed in and requests 'following' feed with 'discover' type_of" do
      let(:another_user) { create(:user) }
      let!(:another_article) { create(:article, user: another_user) }

      before do
        sign_in user
        user.follow(another_user)
      end

      it "returns articles from followed users and others when type_of is 'discover'" do
        get stories_feed_path(type_of: "discover")

        response_article_ids = response.parsed_body.map { |a| a["id"] }
        expect(response_article_ids).to include(article.id, another_article.id)
      end
    end

    context "when user is not signed in and requests 'following' feed" do
      let(:followed_user) { create(:user) }
      let!(:followed_article) { create(:article, user: followed_user) }

      it "returns default signed-out feed" do
        get stories_feed_path(type_of: "following")

        response_article_ids = response.parsed_body.map { |a| a["id"] }
        expect(response_article_ids).to include(article.id, followed_article.id)
      end

      it "returns current_user_signed_in false" do
        get stories_feed_path(type_of: "following")

        expect(response_article["current_user_signed_in"]).to eq(false)
      end
    end
  end

  describe "public_reaction_categories cache invalidation" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      # Create initial reactions
      create(:reaction, reactable: article, category: "like", user: user2)
      create(:reaction, reactable: article, category: "unicorn", user: user3)
    end

    it "returns fresh public_reaction_categories after reactions are added" do
      # Get initial feed response
      get stories_feed_path
      initial_response = response.parsed_body.find { |item| item["id"] == article.id }
      expect(initial_response["public_reaction_categories"].map { |cat| cat["slug"] }).to match_array(%w[like unicorn])

      # Add a new reaction
      create(:reaction, reactable: article, category: "fire", user: user)

      # Get updated feed response
      get stories_feed_path
      updated_response = response.parsed_body.find { |item| item["id"] == article.id }
      expect(updated_response["public_reaction_categories"].map { |cat| cat["slug"] }).to match_array(%w[like unicorn fire])
    end

    it "returns fresh public_reaction_categories after reactions are removed" do
      # Get initial feed response
      get stories_feed_path
      initial_response = response.parsed_body.find { |item| item["id"] == article.id }
      expect(initial_response["public_reaction_categories"].map { |cat| cat["slug"] }).to match_array(%w[like unicorn])

      # Remove a reaction
      article.reactions.find_by(category: "like", user: user2).destroy

      # Get updated feed response
      get stories_feed_path
      updated_response = response.parsed_body.find { |item| item["id"] == article.id }
      expect(updated_response["public_reaction_categories"].map { |cat| cat["slug"] }).to match_array(%w[unicorn])
    end

    it "returns empty public_reaction_categories when no public reactions exist" do
      # Remove all public reactions
      article.reactions.public_category.destroy_all

      get stories_feed_path
      response_article = response.parsed_body.find { |item| item["id"] == article.id }
      expect(response_article["public_reaction_categories"]).to eq([])
    end

    it "does not return stale cached data" do
      # Populate cache with initial data (we have reactions from before block)
      article.public_reaction_categories
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"
      cache_existed = Rails.cache.exist?(cache_key)

      # Add a new reaction (should invalidate cache)
      create(:reaction, reactable: article, category: "fire", user: user)

      # Verify cache was invalidated if it existed
      if cache_existed
        expect(Rails.cache.exist?(cache_key)).to be false
      end

      # Get feed response should show fresh data
      get stories_feed_path
      response_article = response.parsed_body.find { |item| item["id"] == article.id }
      expect(response_article["public_reaction_categories"].map { |cat| cat["slug"] }).to match_array(%w[like unicorn fire])
    end
  end
end
