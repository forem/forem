require "rails_helper"

RSpec.describe EdgeCache::BustArticle, type: :service do
  let(:article) { create(:article) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    allow(article).to receive(:purge)
    allow(article.user).to receive(:purge)
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
    allow(described_class).to receive(:bust_home_pages)
    allow(described_class).to receive(:bust_tag_pages)
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

  it "busts the cache" do
    allow(described_class).to receive(:bust_user_profile_pages)
    described_class.call(article)
    expect(article).to have_received(:purge).once
    allow(article.user).to receive(:purge)
    expect(described_class).to have_received(:bust_home_pages).with(cache_bust, article).once
    expect(described_class).to have_received(:bust_tag_pages).with(cache_bust, article).once
    expect(described_class).to have_received(:bust_user_profile_pages).with(article).once
  end

  it "busts user profile pages" do
    allow(EdgeCache::PurgeByKey).to receive(:call)

    described_class.call(article)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      article.user.profile_cache_keys,
      fallback_paths: article.user.profile_cache_bust_paths
    ).once
  end

  it "does not raise when article has no user" do
    article_without_user = create(:article)
    article_without_user.user = nil
    allow(EdgeCache::PurgeByKey).to receive(:call)

    expect { described_class.call(article_without_user) }.not_to raise_error
  end

  context "when an article is part of an organization" do
    it "busts the organization slug" do
      organization = create(:organization)
      article.organization = organization
      allow(organization).to receive(:purge)

      described_class.call(article)
      expect(organization).to have_received(:purge).once
    end

    it "busts the custom domain article URL when org custom domain is enabled" do
      organization = create(:organization, custom_domain: "blog.example.com")
      article.organization = organization
      allow(organization).to receive(:purge)
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))

      described_class.call(article)
      expect(cache_bust).to have_received(:call).with(URL.url("/#{article.slug}", organization.custom_domain))
    end
  end

  describe "timeframe pruning in bust_home_pages and bust_tag_pages" do
    before do
      allow(described_class).to receive(:bust_home_pages).and_call_original
      allow(described_class).to receive(:bust_tag_pages).and_call_original
    end

    it "stops checking wider timeframes once a recent article is not in the top 3 for week" do
      create_list(:article, 3, :past, tags: "javascript", score: 100, published: true, past_published_at: 2.days.ago)
      low = create(:article, :past, tags: "javascript", score: 1, published: true, past_published_at: 1.day.ago)
      described_class.call(low)
      expect(cache_bust).not_to have_received(:call).with(match(%r{\A/top/(week|month|year|infinity)\z}))
    end

    it "skips narrower timeframes when article was published before the timeframe cutoff" do
      old = create(:article, :past, tags: "ruby", score: 500, published: true, past_published_at: 6.months.ago)
      described_class.call(old)
      expect(cache_bust).not_to have_received(:call).with(match(%r{\A/top/(week|month)\z}))
      expect(cache_bust).to have_received(:call).with("/top/year").at_least(:once)
      expect(cache_bust).to have_received(:call).with("/top/infinity").at_least(:once)
    end

    it "busts top pages for an article in the top 3 among lower-scoring articles" do
      create_list(:article, 2, :past, tags: "go", score: 50, published: true, past_published_at: 2.days.ago)
      create_list(:article, 3, :past, tags: "go", score: 5, published: true, past_published_at: 2.days.ago)
      third = create(:article, :past, tags: "go", score: 20, published: true, past_published_at: 1.day.ago)
      described_class.call(third)
      expect(cache_bust).to have_received(:call).with("/top/week").twice
      expect(cache_bust).to have_received(:call).with("/api/articles?tag=go&top=0").once
    end

    it "ranks by the stored score rather than a stale in-memory score" do
      create_list(:article, 3, :past, tags: "elixir", score: 100, published: true, past_published_at: 2.days.ago)
      low = create(:article, :past, tags: "elixir", score: 1, published: true, past_published_at: 1.day.ago)
      high = create(:article, :past, tags: "rust", score: 500, published: true, past_published_at: 1.day.ago)

      low.score = 1000
      described_class.call(low)
      expect(cache_bust).not_to have_received(:call).with("/api/articles?tag=elixir&top=0")

      high.score = 0
      described_class.call(high)
      expect(cache_bust).to have_received(:call).with("/api/articles?tag=rust&top=0").once
    end

    it "purges each tag API path once even when the article is top in every timeframe" do
      top = create(:article, :past, tags: "ruby, rails", score: 500, published: true, past_published_at: 1.day.ago)
      described_class.call(top)

      %w[ruby rails].each do |tag|
        12.times do |i|
          expect(cache_bust).to have_received(:call).with("/api/articles?tag=#{tag}&top=#{i}").once
        end
      end
      # Once from bust_home_pages and once (not once per tag) from bust_tag_pages
      expect(cache_bust).to have_received(:call).with("/top/week").twice
    end
  end
end
