require "rails_helper"

RSpec.describe "Stories::TaggedArticlesController Performance", type: :request do
  let(:tag) { create(:tag, name: "ruby", supported: true) }
  let!(:articles) do
    # Create multiple articles to test performance with realistic data
    5.times.map do |i|
      article = create(:article, published: true, tags: [tag.name], score: 10 - i)
      # Use update_column to bypass published_at validation for past dates
      article.update_column(:published_at, i.days.ago)
      article
    end
  end

  describe "GET /t/:tag" do
    it "loads tag page successfully with optimizations" do
      get "/t/#{tag.name}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(tag.name)
      expect(response.body).to include("articles-list") # Main content area
    end

    it "uses cached tag count efficiently" do
      # Enable memory store for this test to actually test caching
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      
      begin
        # First request should cache the count
        get "/t/#{tag.name}"
        expect(response).to have_http_status(:success)

        # Verify cache key exists
        cache_key = "#{tag.cache_key}/article-cached-tagged-count"
        expect(Rails.cache.exist?(cache_key)).to be true
        
        # Second request should use cached count
        get "/t/#{tag.name}"
        expect(response).to have_http_status(:success)
      ensure
        Rails.cache = original_cache
      end
    end

    context "with approval required tag" do
      let(:approval_tag) { create(:tag, name: "moderated", requires_approval: true) }
      let!(:approved_article) { create(:article, published: true, approved: true, tags: [approval_tag.name]) }

      it "caches approved article count separately" do
        # Enable memory store for this test
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        
        begin
          get "/t/#{approval_tag.name}"
          expect(response).to have_http_status(:success)
          
          # Verify the specific cache key for approved articles exists
          cache_key = "#{approval_tag.cache_key}/approved-article-count"
          expect(Rails.cache.exist?(cache_key)).to be true
        ensure
          Rails.cache = original_cache
        end
      end
    end
  end

  describe "optimization verification" do
    it "uses optimized service call with Tag object" do
      # Verify that our service optimization works
      expect(Articles::Feeds::Tag).to receive(:call).with(tag, hash_including(number_of_articles: 25, page: 1)).and_call_original
      
      get "/t/#{tag.name}"
      expect(response).to have_http_status(:success)
    end
    
    it "avoids double tag lookup" do
      # Should not do additional Tag.find_by calls in the service
      expect(Tag).to receive(:find_by).once.and_call_original # Only in controller
      
      get "/t/#{tag.name}"
      expect(response).to have_http_status(:success)
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