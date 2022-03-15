require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20200904141057_cleanup_articles_with_invalid_feed_source_url.rb",
)

describe DataUpdateScripts::CleanupArticlesWithInvalidFeedSourceUrl do
  let(:article) { create(:article) }

  it "sets feed_source_url to canonical_url if the latter is present" do
    canonical_url = "https://example.com/article"
    article.update_columns(feed_source_url: "", canonical_url: canonical_url)

    described_class.new.run

    expect(article.reload.feed_source_url).to eq(canonical_url)
  end

  it "sets empty string feed source url to nil" do
    article.update_columns(feed_source_url: "")

    described_class.new.run

    expect(article.reload.feed_source_url).to be_nil
  end

  it "sets totally invalid url to nil" do
    article.update_columns(feed_source_url: "not a url")

    described_class.new.run

    expect(article.reload.feed_source_url).to be_nil
  end

  it "sets an 'almost URL' to a https URL" do
    article.update_columns(feed_source_url: "dev.to")

    described_class.new.run

    expect(article.reload.feed_source_url).to eq("https://dev.to")
  end
end
