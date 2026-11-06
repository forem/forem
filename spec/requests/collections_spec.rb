require "rails_helper"

RSpec.describe "Collections" do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "GET user collections index" do
    it "returns 200" do
      get "/#{user.username}/series"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET user collection show" do
    it "returns 200" do
      get collection.path
      expect(response).to have_http_status(:ok)
    end

    it "paginates the articles in the series", :aggregate_failures do
      stub_const("CollectionsController::ARTICLES_PER_PAGE", 2)
      # Tie the publish times so ordering across pages depends on the id tiebreaker
      tied_time = 1.day.ago
      collection.articles.update_all(published_at: tied_time, crossposted_at: nil)
      articles = collection.articles.order(:id).to_a
      # Rewrite the lowest-id row so its physical position no longer matches id order
      articles.first.update_column(:title, "#{articles.first.title} (edited)")

      get collection.path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(articles.first.path, articles.second.path)
      expect(response.body).not_to include(articles.third.path)

      get collection.path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(articles.third.path)
      expect(response.body).not_to include(articles.first.path)
    end

    it "skips the heavy article columns when loading the series articles", :aggregate_failures do
      article_queries = []
      collector = lambda do |_name, _start, _finish, _id, payload|
        sql = payload[:sql]
        article_queries << sql if sql.include?("FROM \"articles\"") && sql.include?("\"collection_id\"")
      end

      ActiveSupport::Notifications.subscribed(collector, "sql.active_record") do
        get collection.path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(*collection.articles.map(&:path))
      expect(article_queries).not_to be_empty
      expect(article_queries.join).not_to include("\"articles\".*", "body_markdown", "semantic_embedding",
                                                  "reading_list_document")
    end

    it "preloads context notes instead of querying them per article" do
      context_note_queries = 0
      counter = lambda do |_name, _start, _finish, _id, payload|
        context_note_queries += 1 if payload[:sql].include?("\"context_notes\"")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get collection.path
      end

      expect(context_note_queries).to eq(1)
    end

    it "reads the listed articles' tag colors in one cache batch", :aggregate_failures do
      allow(Rails.cache).to receive(:fetch).and_call_original
      allow(Rails.cache).to receive(:fetch_multi).and_call_original

      get collection.path

      tags = collection.articles.flat_map { |article| article.decorate.cached_tag_list_array }.uniq
      expect(Rails.cache).to have_received(:fetch_multi).with(*tags.map { |tag| "view-helper-#{tag}/tag_colors" },
                                                              expires_in: 5.hours).once
      expect(Rails.cache).not_to have_received(:fetch).with(a_string_ending_with("/tag_colors"), any_args)
      expect(response.body).to include(*tags.map { |tag| %(href="/t/#{tag}") })
    end

    it "preloads reaction counts for reacted series articles in one batch", :aggregate_failures do
      reacted_articles = collection.articles.order(:id).first(2)
      reacted_articles.each do |article|
        create(:reaction, reactable: article, category: "like")
        article.update_column(:public_reactions_count, 1)
      end

      allow(Rails.cache).to receive(:read_multi).and_call_original
      allow(Rails.cache).to receive(:fetch).and_call_original

      reaction_queries = 0
      counter = lambda do |_name, _start, _finish, _id, payload|
        reaction_queries += 1 if payload[:sql].include?("FROM \"reactions\"")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get collection.path
      end

      expect(response).to have_http_status(:ok)
      expect(reaction_queries).to eq(1)
      expect(Rails.cache).to have_received(:read_multi).with(
        *reacted_articles.map(&:reaction_counts_cache_key),
      ).once
      expect(Rails.cache).not_to have_received(:fetch).with(
        a_string_starting_with("reaction_counts_for_reactable-Article-"),
        any_args,
      )
    end
  end

  describe "GET large user collection show" do
    it "returns the proper article count and text for a large collection", :aggregate_failures do
      amount = 6
      large_collection = create(:collection, :with_articles, amount: amount, user: user)

      get "/#{user.username}/#{large_collection.articles.first.slug}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include "#{amount - 4} more parts..."
    end
  end
end
