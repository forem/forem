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
