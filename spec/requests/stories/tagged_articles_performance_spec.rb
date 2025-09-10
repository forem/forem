require "rails_helper"

RSpec.describe "Stories::TaggedArticlesController Performance", type: :request do
  let(:tag) { create(:tag, name: "ruby", supported: true) }
  let!(:articles) do
    # Create multiple articles to test performance with realistic data
    10.times.map do |i|
      article = create(:article, published: true, tags: [tag.name], score: 10 - i)
      # Use update_column to bypass published_at validation for past dates
      article.update_column(:published_at, i.days.ago)
      article
    end
  end

  describe "GET /t/:tag" do
    it "executes efficiently with minimal database queries" do
      # Enable query counting to measure performance
      query_count = 0
      query_callback = lambda do |_name, _start, _finish, _message_id, values|
        query_count += 1 unless values[:sql].include?("SCHEMA")
      end

      ActiveSupport::Notifications.subscribed(query_callback, "sql.active_record") do
        get "/t/#{tag.name}"
      end

      expect(response).to have_http_status(:success)
      
      # With optimizations, we should have significantly fewer queries
      # This is a baseline - adjust based on actual measurements
      expect(query_count).to be < 15, "Expected fewer than 15 queries, got #{query_count}"
    end

    it "uses cached tag count efficiently" do
      # First request should cache the count
      get "/t/#{tag.name}"
      expect(response).to have_http_status(:success)

      # Mock Rails.cache to verify cache usage
      expect(Rails.cache).to receive(:fetch)
        .with("#{tag.cache_key}/article-cached-tagged-count", expires_in: 2.hours)
        .and_call_original

      # Second request should use cached count
      get "/t/#{tag.name}"
      expect(response).to have_http_status(:success)
    end

    context "with approval required tag" do
      let(:approval_tag) { create(:tag, name: "moderated", requires_approval: true) }
      let!(:approved_article) { create(:article, published: true, approved: true, tags: [approval_tag.name]) }

      it "caches approved article count separately" do
        expect(Rails.cache).to receive(:fetch)
          .with("#{approval_tag.cache_key}/approved-article-count", expires_in: 1.hour)
          .and_call_original

        get "/t/#{approval_tag.name}"
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "established? optimization" do
    let(:controller) { Stories::TaggedArticlesController.new }
    let(:stories) { Article.cached_tagged_with(tag.name) }

    before do
      controller.instance_variable_set(:@num_published_articles, 5)
    end

    it "uses cached count instead of database query when available" do
      # Should not execute additional queries when cached count is available
      expect(stories).not_to receive(:exists?)
      
      result = controller.send(:established?, stories: stories, tag: tag)
      expect(result).to be true
    end
  end
end