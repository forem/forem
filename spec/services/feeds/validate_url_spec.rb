require "rails_helper"

RSpec.describe Feeds::ValidateUrl, :vcr, type: :service do
  let(:invalid_feed_url) { "https://example.com" }
  let(:valid_feed_url) { "https://medium.com/feed/@vaidehijoshi" }
  let(:hashnode_feed_url) { "https://hashnode.blog/rss.xml" }

  it "returns false for empty URL" do
    expect(described_class.call("")).to be(false)
  end

  it "returns false for an invalid feed URL", vcr: { cassette_name: "feeds_validate_url_invalid" } do
    expect(described_class.call(invalid_feed_url)).to be(false)
  end

  it "returns true for an valid feed URL", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
    expect(described_class.call(valid_feed_url)).to be(true)
  end

  it "returns true for a valid Hashnode RSS feed", vcr: { cassette_name: "feeds_validate_url_hashnode" } do
    expect(described_class.call(hashnode_feed_url)).to be(true)
  end
end