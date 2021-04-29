require "rails_helper"

RSpec.describe "Search", type: :request, proper_status: true do
  let(:authorized_user) { create(:user) }

  describe "GET /search/tags" do
    before do
      sign_in authorized_user
    end

    it "returns nothing if there is no name parameter" do
      get search_tags_path
      expect(response.parsed_body["result"]).to be_empty
    end

    it "finds a tag by a partial name" do
      tag = create(:tag, name: "elixir")

      get search_tags_path(name: "eli")

      expect(response.parsed_body["result"].first).to include("name" => tag.name)
    end
  end

  describe "GET /search/chat_channels" do
    let(:authorized_user) { create(:user) }
    let(:mock_documents) do
      [{ "channel_name" => "channel1" }]
    end

    it "returns json" do
      sign_in authorized_user
      allow(Search::Postgres::ChatChannelMembership).to receive(:search_documents).and_return(
        mock_documents,
      )
      get "/search/chat_channels"
      expect(response.parsed_body).to eq("result" => mock_documents)
    end
  end

  describe "GET /search/listings" do
    it "returns the correct keys" do
      create(:listing)
      get search_listings_path
      expect(response.parsed_body["result"]).to be_present
    end

    it "supports the search params" do
      listing = create(:listing)

      get search_listings_path(
        category: listing.category,
        page: 0,
        per_page: 1,
        term: listing.title.downcase,
      )

      expect(response.parsed_body["result"].first).to include("title" => listing.title)
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
    before do
      sign_in authorized_user
    end

    it "returns nothing if there is no username parameter" do
      get search_usernames_path
      expect(response.parsed_body["result"]).to be_empty
    end

    it "finds a username by a partial username" do
      user = create(:user, username: "Sloan")

      get search_usernames_path(username: "slo")

      expect(response.parsed_body["result"].first).to include("username" => user.username)
    end

    it "finds a username by a partial name" do
      user = create(:user, name: "Sloan")

      get search_usernames_path(username: "slo")

      expect(response.parsed_body["result"].first).to include("username" => user.username)
    end
  end

  describe "GET /search/feed_content" do
    context "when using Elasticsearch" do
      let(:mock_documents) { [{ "title" => "article1" }] }

      it "returns json" do
        allow(Search::FeedContent).to receive(:search_documents).and_return(
          mock_documents,
        )

        get search_feed_content_path
        expect(response.parsed_body["result"]).to eq(mock_documents)
      end

      it "queries only the user index if class_name=User" do
        allow(Search::FeedContent).to receive(:search_documents)
        allow(Search::User).to receive(:search_documents).and_return(
          mock_documents,
        )

        get search_feed_content_path(class_name: "User")
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

        get search_feed_content_path
        expect(Search::User).to have_received(:search_documents)
        expect(Search::FeedContent).to have_received(:search_documents)
      end

      it "queries for only Articles and Podcast Episodes if class_name!=User" do
        allow(Search::FeedContent).to receive(:search_documents).and_return(
          mock_documents,
        )
        allow(Search::User).to receive(:search_documents)

        get search_feed_content_path(class_name: "Article")
        expect(Search::User).not_to have_received(:search_documents)
        expect(Search::FeedContent).to have_received(:search_documents)
      end

      it "queries for approved" do
        allow(Search::FeedContent).to receive(:search_documents).and_return(
          mock_documents,
        )

        get search_feed_content_path(class_name: "Article", approved: "true")
        expect(Search::FeedContent).to have_received(:search_documents).with(
          params: { "approved" => "true", "class_name" => "Article" },
        )
      end
    end

    context "when using PostgreSQL for the homepage" do
      let(:homepage_params) { { class_name: "Article", sort_by: "published_at", sort_direction: "desc" } }

      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_articles, anything).and_return(true)
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_homepage, anything).and_return(true)
      end

      it "does not call Homepage::FetchArticles when class_name is Article with a search term", :aggregate_failures do
        allow(Homepage::FetchArticles).to receive(:call)

        get search_feed_content_path
        expect(Homepage::FetchArticles).not_to have_received(:call)

        get search_feed_content_path(class_name: "Article", search_fields: "keyword")
        expect(Homepage::FetchArticles).not_to have_received(:call)
      end

      it "calls Homepage::FetchArticles when class_name is Article" do
        allow(Homepage::FetchArticles).to receive(:call)

        get search_feed_content_path(homepage_params)

        expect(Homepage::FetchArticles).to have_received(:call)
      end

      it "returns the correct keys", :aggregate_failures do
        create(:article)

        get search_feed_content_path(homepage_params)

        expect(response.parsed_body["result"]).to be_present
      end

      it "parses published_at correctly", :aggregate_failures do
        article = create(:article)

        get search_feed_content_path(homepage_params.merge(published_at: { gte: article.published_at.iso8601 }))
        expect(response.parsed_body["result"].first["id"]).to eq(article.id)

        datetime = article.published_at + 1.minute
        get search_feed_content_path(homepage_params.merge(published_at: { gte: datetime.iso8601 }))
        expect(response.parsed_body["result"]).to be_empty
      end

      it "supports the user_id parameter" do
        allow(Homepage::FetchArticles).to receive(:call)

        get search_feed_content_path(homepage_params.merge(user_id: 1))

        expect(Homepage::FetchArticles).to have_received(:call).with(hash_including(user_id: "1"))
      end

      it "supports the organization_id parameter" do
        allow(Homepage::FetchArticles).to receive(:call)

        get search_feed_content_path(homepage_params.merge(organization_id: 1))

        expect(Homepage::FetchArticles).to have_received(:call).with(hash_including(organization_id: "1"))
      end

      it "supports the tag_names parameter" do
        allow(Homepage::FetchArticles).to receive(:call)

        get search_feed_content_path(homepage_params.merge(tag_names: %i[ruby]))

        expect(Homepage::FetchArticles).to have_received(:call).with(hash_including(tags: %w[ruby]))
      end
    end

    context "when using PostgreSQL for articles" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_articles, anything).and_return(true)
      end

      it "calls Search::Postgres::Article without a class_name" do
        allow(Search::Postgres::Article).to receive(:search_documents)

        get search_feed_content_path

        expect(Search::Postgres::Article).to have_received(:search_documents)
      end

      it "calls Search::Postgres::Article without a class_name with :search_2_homepage active" do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_homepage, anything).and_return(true)
        allow(Search::Postgres::Article).to receive(:search_documents)

        get search_feed_content_path

        expect(Search::Postgres::Article).to have_received(:search_documents)
      end

      it "calls Search::Postgres::Article with class_name=Article with :search_2_homepage active" do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_homepage, anything).and_return(true)
        allow(Search::Postgres::Article).to receive(:search_documents)

        get search_feed_content_path(class_name: "Article")

        expect(Search::Postgres::Article).to have_received(:search_documents)
      end

      it "supports the search params", :aggregate_failures do
        allow(Search::Postgres::Article).to receive(:search_documents).and_call_original

        article = create(:article)

        get search_feed_content_path(
          class_name: "Article", page: 0, per_page: 1, search_fields: article.title,
          sort_by: :published_at, sort_direction: :desc
        )

        expect(response.parsed_body["result"].first["id"]).to eq(article.id)

        expect(Search::Postgres::Article).to have_received(:search_documents)
      end
    end

    context "when using PostgreSQL for comments" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_comments).and_return(true)
      end

      it "returns the correct keys for comments" do
        create(:comment, body_markdown: "Ruby on Rails rocks!")
        get search_feed_content_path(search_fields: "rails", class_name: "Comment")
        expect(response.parsed_body["result"]).to be_present
      end

      it "supports the search params for comments" do
        comment = create(:comment, body_markdown: "Ruby on Rails rocks!")
        get search_feed_content_path(
          search_fields: "rails",
          class_name: "Comment",
          page: 0,
          per_page: 1,
        )

        expect(response.parsed_body["result"].first).to include("body_text" => comment.body_markdown)
      end
    end

    context "when using PostgreSQL for users" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_users).and_return(true)
      end

      it "returns the correct keys", :aggregate_failures do
        create(:user)

        get search_feed_content_path(class_name: "User")

        expect(response.parsed_body["result"]).to be_present
      end

      it "supports the search params" do
        user = create(:user)

        get search_feed_content_path(
          class_name: "User", page: 0, per_page: 1, search_fields: user.name,
          sort_by: :created_at, sort_direction: :desc
        )

        expect(response.parsed_body["result"].first["id"]).to eq(user.id)
      end
    end

    context "when using PostgreSQL for podcasts" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_podcast_episodes).and_return(true)
      end

      it "returns the correct keys for podcasts" do
        create(:podcast_episode, body: "DHH talks about how Ruby on Rails rocks!")
        get search_feed_content_path(search_fields: "rails", class_name: "PodcastEpisode")
        expect(response.parsed_body["result"]).to be_present
      end

      it "supports the search params for podcasts" do
        podcast_episode = create(:podcast_episode, body: "DHH talks about how Ruby on Rails rocks!")
        get search_feed_content_path(
          search_fields: "rails",
          class_name: "PodcastEpisode",
          page: 0,
          per_page: 1,
        )

        expect(response.parsed_body["result"].first).to include("body_text" => podcast_episode.body_text)
      end
    end
  end

  describe "GET /search/reactions" do
    before do
      sign_in authorized_user
    end

    context "when using Elasticsearch" do
      let(:mock_response) do
        { "reactions" => [{ id: 123 }], "total" => 100 }
      end

      before do
        allow(Search::ReadingList).to receive(:search_documents).and_return(mock_response)
      end

      it "returns json with reactions and total" do
        get search_reactions_path

        expect(response.parsed_body).to eq("result" => [{ "id" => 123 }], "total" => 100)
      end

      it "accepts array of tag names" do
        get search_reactions_path(tag_names: [1, 2])

        expect(Search::ReadingList).to(
          have_received(:search_documents)
            .with(params: { "tag_names" => %w[1 2] }, user: authorized_user),
        )
      end
    end

    context "when using PostgreSQL" do
      let(:article) { create(:article) }

      before do
        allow(FeatureFlag).to receive(:enabled?).with(:search_2_reading_list).and_return(true)
        create(:reaction, category: :readinglist, reactable: article, user: authorized_user)
      end

      it "returns the correct keys", :aggregate_failures do
        get search_reactions_path

        expect(response.parsed_body["result"]).to be_present
        expect(response.parsed_body["total"]).to eq(1)
      end

      it "supports the search params" do
        article.update_columns(title: "Title", cached_tag_list: "ruby, python")

        get search_reactions_path(page: 0, per_page: 1, status: %w[valid], tags: %w[ruby], term: "title")

        expect(response.parsed_body["result"].first["reactable"]).to include("title" => "Title")
      end
    end
  end
end
