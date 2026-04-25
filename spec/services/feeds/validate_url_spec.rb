require "rails_helper"

RSpec.describe Feeds::ValidateUrl, :vcr, type: :service do
  let(:invalid_feed_url) { "https://example.com" }
  let(:valid_feed_url) { "https://medium.com/feed/@vaidehijoshi" }

  it "returns false for empty URL" do
    expect(described_class.call("")).to be(false)
  end

  it "returns false for an invalid feed URL", vcr: { cassette_name: "feeds_validate_url_invalid" } do
    expect(described_class.call(invalid_feed_url)).to be(false)
  end

  it "returns true for an valid feed URL", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
    expect(described_class.call(valid_feed_url)).to be(true)
  end

  it "raises with a descriptive message for a 403 response" do
    stub_request(:get, "https://example.com/feed.xml")
      .to_return(status: 403, body: "<html>Forbidden</html>", headers: {})

    expect { described_class.call("https://example.com/feed.xml") }
      .to raise_error(StandardError, /could not be retrieved — it may be protected/)
  end

  it "raises with a descriptive message for a 429 response" do
    stub_request(:get, "https://example.com/feed.xml")
      .to_return(status: 429, body: "<html>Too Many Requests</html>", headers: {})

    expect { described_class.call("https://example.com/feed.xml") }
      .to raise_error(StandardError, /could not be retrieved — it may be protected/)
  end

  it "returns false for other non-2xx responses" do
    stub_request(:get, "https://example.com/feed.xml")
      .to_return(status: 404, body: "", headers: {})

    expect(described_class.call("https://example.com/feed.xml")).to be(false)
  end
end
