require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20200904141057_cleanup_articles_with_invalid_feed_source_url.rb",
)

describe DataUpdateScripts::CleanupArticlesWithInvalidFeedSourceUrl do
  it "sets empty string feed source url to nil" do
    article = create(:article)
    article.update_columns(feed_source_url: "")

    described_class.new.run

    expect(article.reload.feed_source_url).to be(nil)
  end

  it "sets totally invalid url to nil" do
    article = create(:article)
    article.update_columns(feed_source_url: "not a url")

    described_class.new.run

    expect(article.reload.feed_source_url).to be(nil)
  end

  it "sets an 'almost URL' to a https URL" do
    article = create(:article)
    article.update_columns(feed_source_url: "dev.to")

    described_class.new.run

    expect(article.reload.feed_source_url).to eq("https://dev.to")
  end
end
