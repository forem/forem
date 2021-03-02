require "rails_helper"

RSpec.describe EdgeCache::BustArticle, type: :service do
  let(:article) { create(:article) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    allow(article).to receive(:purge)
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
    described_class.call(article)
    expect(article).to have_received(:purge).once
    expect(cache_bust).to have_received(:call).exactly(9).times
    expect(cache_bust).to have_received(:call).with(article.path).once
    expect(described_class).to have_received(:bust_home_pages).with(cache_bust, article).once
    expect(described_class).to have_received(:bust_tag_pages).with(cache_bust, article).once
  end

  context "when an article is part of an organization" do
    it "busts the organization slug" do
      organization = create(:organization)
      article.organization = organization

      described_class.call(article)
      expect(cache_bust).to have_received(:call).with("/#{article.organization.slug}").once
    end
  end
end
