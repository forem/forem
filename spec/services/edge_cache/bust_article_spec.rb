require "rails_helper"

RSpec.describe EdgeCache::BustArticle, type: :service do
  let(:article) { create(:article) }

  before do
    article
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "defines TIMEFRAMES" do
    expect(described_class.const_defined?(:TIMEFRAMES)).to be true
  end

  it "adjusts TIMEFRAMES according to the current time" do
    current_year = Time.current.year

    Timecop.freeze(3.years.ago) do
      timestamp, _interval = described_class::TIMEFRAMES.first
      expect(timestamp.call.year).to be <= current_year - 3
    end
  end

  it "batches article and user surrogate keys into a single EdgeCache::PurgeByKey call", :aggregate_failures do
    described_class.call(article)

    expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
      expect(keys).to include(article.record_key, *article.user.profile_cache_keys)
      expect(fallback_paths).to include(article.path, *article.user.profile_cache_bust_paths)
    end
  end

  it "does not raise when article has no user" do
    article_without_user = create(:article)
    article_without_user.user = nil
    RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
    allow(EdgeCache::PurgeByKey).to receive(:call)

    expect { described_class.call(article_without_user) }.not_to raise_error
    expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
      expect(keys).to include(article_without_user.record_key)
      expect(fallback_paths).to include(article_without_user.path)
    end
  end

  context "when an article is part of an organization" do
    it "includes the organization surrogate key and fallback path" do
      organization = create(:organization)
      article.organization = organization
      RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
      allow(EdgeCache::PurgeByKey).to receive(:call)

      described_class.call(article)

      expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
        expect(keys).to include(organization.record_key)
        expect(fallback_paths).to include(organization.path)
      end
    end

    it "includes the custom domain article URL in fallback_paths when org custom domain is enabled" do
      organization = create(:organization, custom_domain: "blog.example.com")
      article.organization = organization
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
      RSpec::Mocks.space.proxy_for(EdgeCache::PurgeByKey).reset
      allow(EdgeCache::PurgeByKey).to receive(:call)

      described_class.call(article)

      expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
        expect(keys).to include(organization.record_key)
        expect(fallback_paths).to include(URL.url("/#{article.slug}", organization.custom_domain))
      end
    end
  end

  describe "timeframe pruning in home and tag target collection" do
    def captured_purge_for(target_article)
      captured = nil
      allow(EdgeCache::PurgeByKey).to receive(:call) do |keys, fallback_paths:|
        captured = { keys: keys, fallback_paths: fallback_paths }
      end
      described_class.call(target_article)
      captured
    end

    it "stops checking wider timeframes once a recent article is not in the top 3 for week" do
      create_list(:article, 3, :past, tags: "javascript", score: 100, published: true, past_published_at: 2.days.ago)
      low = create(:article, :past, tags: "javascript", score: 1, published: true, past_published_at: 1.day.ago)

      result = captured_purge_for(low)

      expect(result[:keys]).not_to include(match(/\Astories-top-(week|month|year|infinity)\z/))
      expect(result[:fallback_paths]).not_to include(match(%r{\A/top/(week|month|year|infinity)\z}))
    end

    it "skips narrower timeframes when article was published before the timeframe cutoff" do
      old = create(:article, :past, tags: "ruby", score: 500, published: true, past_published_at: 6.months.ago)

      result = captured_purge_for(old)

      expect(result[:keys]).not_to include("stories-top-week", "stories-top-month")
      expect(result[:keys]).to include("stories-top-year", "stories-top-infinity",
                                       "tag-ruby-top-year", "tag-ruby-top-infinity", "api-articles-tag-ruby-top")
      expect(result[:fallback_paths]).not_to include("/top/week", "/top/month")
      expect(result[:fallback_paths]).to include("/top/year", "/top/infinity")
    end

    it "busts top surrogate keys and fallback paths for an article in the top 3 among lower-scoring articles" do
      create_list(:article, 2, :past, tags: "go", score: 50, published: true, past_published_at: 2.days.ago)
      create_list(:article, 3, :past, tags: "go", score: 5, published: true, past_published_at: 2.days.ago)
      third = create(:article, :past, tags: "go", score: 20, published: true, past_published_at: 1.day.ago)

      result = captured_purge_for(third)

      expect(result[:keys]).to include("stories-top-week", "tag-go-top-week", "api-articles-tag-go-top")
      expect(result[:fallback_paths]).to include("/top/week", "/t/go/top/week", "/api/articles?tag=go&top=0")
    end

    it "ranks by the stored score rather than a stale in-memory score" do
      create_list(:article, 3, :past, tags: "elixir", score: 100, published: true, past_published_at: 2.days.ago)
      low = create(:article, :past, tags: "elixir", score: 1, published: true, past_published_at: 1.day.ago)
      high = create(:article, :past, tags: "rust", score: 500, published: true, past_published_at: 1.day.ago)

      low.score = 1000
      low_result = captured_purge_for(low)
      expect(low_result[:keys]).not_to include("api-articles-tag-elixir-top")
      expect(low_result[:fallback_paths]).not_to include("/api/articles?tag=elixir&top=0")

      high.score = 0
      high_result = captured_purge_for(high)
      expect(high_result[:keys]).to include("api-articles-tag-rust-top")
      expect(high_result[:fallback_paths]).to include("/api/articles?tag=rust&top=0")
    end

    it "deduplicates surrogate keys and fallback paths across multiple tags and timeframes" do
      top = create(:article, :past, tags: "ruby, rails", score: 500, published: true, past_published_at: 1.day.ago)

      result = captured_purge_for(top)

      expect(result[:keys]).to eq(result[:keys].uniq)
      expect(result[:fallback_paths]).to eq(result[:fallback_paths].uniq)
      expect(result[:keys]).to include("api-articles-tag-ruby-top", "api-articles-tag-rails-top")
    end

    it "bounds hotness_score checks and ranks by the stored hotness_score" do
      allow(described_class).to receive(:rand).with(2).and_return(1)

      create_list(:article, 4, :past, tags: "go", hotness_score: 500, published: true, past_published_at: 2.days.ago)
      low_hot = create(:article, :past, tags: "go", hotness_score: 50, published: true, past_published_at: 2.days.ago)
      top_hot = create(:article, :past, tags: "go", hotness_score: 900, published: true, past_published_at: 2.days.ago)

      low_hot.hotness_score = 10_000
      low_result = captured_purge_for(low_hot)
      expect(low_result[:keys]).not_to include("tag-go-home", "main_app_home_page")
      expect(low_result[:fallback_paths]).not_to include("/t/go", "/")

      top_hot.hotness_score = 0
      top_result = captured_purge_for(top_hot)
      expect(top_result[:keys]).to include("tag-go-home", "main_app_home_page")
      expect(top_result[:fallback_paths]).to include("/t/go", "/")
    end
  end
end
