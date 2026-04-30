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
  end
end
