# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::RSS do
  describe "#will_parse?" do
    it "returns true for an RSS feed" do
      expect(described_class).to be_able_to_parse(sample_rss_feed)
    end

    it "returns false for an atom feed" do
      expect(described_class).not_to be_able_to_parse(sample_atom_feed)
    end

    it "returns false for an rss feedburner feed" do
      able = described_class.able_to_parse? sample_rss_feed_burner_feed
      expect(able).to be false
    end
  end

  describe "parsing" do
    before do
      @feed = described_class.parse(sample_rss_feed)
    end

    it "parses the version" do
      expect(@feed.version).to eq "2.0"
    end

    it "parses the title" do
      expect(@feed.title).to eq "Tender Lovemaking"
    end

    it "parses the description" do
      expect(@feed.description).to eq "The act of making love, tenderly."
    end

    it "parses the url" do
      expect(@feed.url).to eq "http://tenderlovemaking.com"
    end

    it "parses the ttl" do
      expect(@feed.ttl).to eq "60"
    end

    it "parses the last build date" do
      expect(@feed.last_built).to eq "Sat, 07 Sep 2002 09:42:31 GMT"
    end

    it "parses the hub urls" do
      expect(@feed.hubs.count).to eq 1
      expect(@feed.hubs.first).to eq "http://pubsubhubbub.appspot.com/"
    end

    it "provides an accessor for the feed_url" do
      expect(@feed).to respond_to :feed_url
      expect(@feed).to respond_to :feed_url=
    end

    it "parses the language" do
      expect(@feed.language).to eq "en"
    end

    it "parses the image url" do
      expect(@feed.image.url).to eq "https://tenderlovemaking.com/images/header-logo-text-trimmed.png"
    end

    it "parses the image title" do
      expect(@feed.image.title).to eq "Tender Lovemaking"
    end

    it "parses the image link" do
      expect(@feed.image.link).to eq "http://tenderlovemaking.com"
    end

    it "parses the image width" do
      expect(@feed.image.width).to eq "766"
    end

    it "parses the image height" do
      expect(@feed.image.height).to eq "138"
    end

    it "parses the image description" do
      expect(@feed.image.description).to eq "The act of making love, tenderly."
    end

    it "parses entries" do
      expect(@feed.entries.size).to eq 10
    end
  end
end
