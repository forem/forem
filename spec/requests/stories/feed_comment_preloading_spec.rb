require "rails_helper"

RSpec.describe "Feed comment preview loading" do
  let(:author) { create(:user) }
  let(:viewer) { create(:user) }
  let(:articles) { create_list(:article, 2, user: author, featured: true, score: 100, tags: "ruby") }
  let(:comments) do
    articles.flat_map do |article|
      Array.new(6) do |index|
        create(:comment, commentable: article, user: author, score: 20,
                         body_markdown: "Preview #{article.id}-#{index}", created_at: (10 - index).minutes.ago)
      end
    end
  end

  before do
    comments
    articles.each { |article| article.update_columns(score: 100, published_at: 1.day.ago) }
    sign_in viewer
  end

  def capture_comment_loading(&block)
    result = { queries: [], rows: 0 }
    sql_callback = lambda do |*, payload|
      result[:queries] << payload[:sql] if payload[:sql].include?('FROM "comments"') && payload[:name] != "SCHEMA"
    end
    instantiation_callback = lambda do |*, payload|
      result[:rows] += payload[:record_count] if payload[:class_name] == "Comment"
    end

    ActiveSupport::Notifications.subscribed(sql_callback, "sql.active_record") do
      ActiveSupport::Notifications.subscribed(instantiation_callback, "instantiation.active_record", &block)
    end
    result
  end

  def expected_previews(article)
    comments.select { |comment| comment.commentable_id == article.id }
      .sort_by(&:created_at).last(3).reverse.map do |comment|
        {
          "comment_id" => comment.id,
          "user_id" => author.id,
          "published_timestamp" => comment.decorate.published_timestamp,
          "published_at_int" => comment.decorate.published_at_int,
          "safe_processed_html" => comment.safe_processed_html,
          "path" => comment.path,
          "username" => author.username,
          "name" => author.name,
          "profile_image_90" => author.profile_image_90
        }
      end
  end

  %w[basic configured weighted large_forem_experimental].each do |strategy|
    context "with the #{strategy} strategy" do
      before { allow(Settings::UserExperience).to receive(:feed_strategy).and_return(strategy) }

      it "loads only three previews per article in one narrow query and preserves the JSON payload" do
        create(:feed_config) if strategy == "configured"

        loading = capture_comment_loading { get stories_feed_path }

        expect(response).to have_http_status(:ok)
        articles.each do |article|
          card = response.parsed_body.detect { |item| item["id"] == article.id }
          expect(card.fetch("top_comments")).to eq(expected_previews(article))
        end
        expect(loading[:rows]).to eq(6)
        expect(loading[:queries].size).to eq(1)
        projection = loading[:queries].first.split(" FROM ").first
        expect(projection).to include('"comments"."processed_html"')
        expect(projection).not_to include('"comments".*', '"body_markdown"', '"body_html"', '"semantic_embedding"')
      end

      context "with fragment caching" do
        around do |example|
          original = ActionController::Base.perform_caching
          ActionController::Base.perform_caching = true
          example.run
        ensure
          ActionController::Base.perform_caching = original
        end

        before do
          allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
          create(:feed_config) if strategy == "configured"
        end

        it "loads no comment rows on a fully cached feed and returns identical cards" do
          get stories_feed_path
          first_payload = response.parsed_body

          loading = capture_comment_loading { get stories_feed_path }

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.sort_by { |item| item["id"] }).to eq(first_payload.sort_by { |item| item["id"] })
          expect(loading).to eq(queries: [], rows: 0)
        end

        it "loads previews only for the changed card on a partial cache hit" do
          get stories_feed_path
          unchanged_card = response.parsed_body.detect { |item| item["id"] == articles.last.id }
          articles.first.update_column(:last_comment_at, 1.minute.from_now)

          loading = capture_comment_loading { get stories_feed_path }

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.detect { |item| item["id"] == articles.last.id }).to eq(unchanged_card)
          expect(loading[:rows]).to eq(3)
          expect(loading[:queries].size).to eq(1)
        end
      end
    end
  end

  it "excludes replies, hidden, deleted, and low-score comments before choosing previews" do
    allow(Settings::UserExperience).to receive(:feed_strategy).and_return("configured")
    create(:feed_config)
    create(:comment, commentable: articles.first, user: author, parent: comments.first, score: 30)
    create(:comment, commentable: articles.first, user: author, hidden_by_commentable_user: true, score: 30)
    create(:comment, commentable: articles.first, user: author, deleted: true, score: 30)
    create(:comment, commentable: articles.first, user: author, score: 4)
    comments << create(
      :comment,
      commentable: articles.first,
      user: author,
      score: 5,
      body_markdown: "Newest eligible comment at the score boundary",
    )

    loading = capture_comment_loading { get stories_feed_path }

    card = response.parsed_body.detect { |item| item["id"] == articles.first.id }
    expect(card.fetch("top_comments")).to eq(expected_previews(articles.first))
    expect(loading[:rows]).to eq(6)
    expect(articles.first.more_inclusive_recent_good_comments.count).to eq(7)
  end

  it "does not preload feed comments while rendering the HTML home page" do
    allow(Settings::UserExperience).to receive(:feed_strategy).and_return("large_forem_experimental")

    loading = capture_comment_loading { get "/" }

    expect(response).to have_http_status(:ok)
    expect(loading).to eq(queries: [], rows: 0)
  end

  it "renders the same bounded previews for signed-out visitors" do
    sign_out viewer
    allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")

    loading = capture_comment_loading { get stories_feed_path }

    expect(response).to have_http_status(:ok)
    articles.each do |article|
      card = response.parsed_body.detect { |item| item["id"] == article.id }
      expect(card.fetch("top_comments")).to eq(expected_previews(article))
    end
    expect(loading[:rows]).to eq(6)
    expect(loading[:queries].size).to eq(1)
  end

  it "does not load comments for an article with no comments" do
    allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
    empty_article = create(:article, user: author, featured: true, score: 100)

    loading = capture_comment_loading { get stories_feed_path }

    card = response.parsed_body.detect { |item| item["id"] == empty_article.id }
    expect(card.fetch("top_comments")).to eq([])
    expect(loading[:rows]).to eq(6)
  end

  it "loads previews for a pinned article outside the selected feed" do
    allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
    pinned = create(:article, user: author)
    pinned_comments = create_list(:comment, 5, commentable: pinned, user: author, score: 20)
    pinned.update_columns(score: -1000, featured: false)
    PinnedArticle.set(pinned)

    loading = capture_comment_loading { get stories_feed_path }

    expect(response).to have_http_status(:ok)
    card = response.parsed_body.first
    expect(card.fetch("id")).to eq(pinned.id)
    expect(card.fetch("top_comments").size).to eq(3)
    expect(card.fetch("top_comments").pluck("comment_id")).to match_array(pinned_comments.last(3).map(&:id))
    expect(loading[:rows]).to eq(9)
    expect(loading[:queries].size).to eq(1)
  end

  it "keeps later-page previews bounded even when fragment caching is enabled" do
    allow(Articles::Feeds::Latest).to receive(:call).with(tag: nil, page: 3)
      .and_return(Article.where(id: articles.map(&:id)).limited_column_select)
    original = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true

    loading = capture_comment_loading { get stories_feed_path(page: 3, timeframe: "latest") }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("id")).to match_array(articles.map(&:id))
    expect(loading[:rows]).to eq(6)
    expect(loading[:queries].size).to eq(1)
  ensure
    ActionController::Base.perform_caching = original
  end
end
