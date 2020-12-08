require "rails_helper"

RSpec.describe EdgeCache::BustArticle, type: :service do
  let(:article) { create(:article) }

  before do
    allow(article).to receive(:purge)
    allow(described_class).to receive(:bust)
    allow(described_class).to receive(:bust_home_pages)
    allow(described_class).to receive(:bust_tag_pages)
  end

  it "busts the cache" do
    described_class.call(article)
    expect(article).to have_received(:purge).once
    expect(described_class).to have_received(:bust).exactly(9).times
    expect(described_class).to have_received(:bust).with(article.path).once
    expect(described_class).to have_received(:bust_home_pages).with(article).once
    expect(described_class).to have_received(:bust_tag_pages).with(article).once
  end

  context "when an article is part of an organization" do
    it "busts the organization slug" do
      organization = create(:organization)
      article.organization = organization

      described_class.call(article)
      expect(described_class).to have_received(:bust).with("/#{article.organization.slug}").once
    end
  end
end
