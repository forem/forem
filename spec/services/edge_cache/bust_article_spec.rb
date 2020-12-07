require "rails_helper"

RSpec.describe EdgeCache::BustArticle, type: :service do
  let(:article) { create(:article) }

  before do
    allow(article).to receive(:purge)
    allow(described_class).to receive(:bust)
  end

  it "busts the cache" do
    described_class.call(article)
    expect(article).to have_received(:purge).once
    expect(described_class).to have_received(:bust).with(article.path).once
  end
end
