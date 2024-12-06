# frozen_string_literal: true

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Feedjira::Parser::AtomYoutube do
  describe "#will_parse?" do
    it "returns true for an atom youtube feed" do
      expect(described_class).to be_able_to_parse(sample_youtube_atom_feed)
    end

    it "returns fase for an atom feed" do
      expect(described_class).not_to be_able_to_parse(sample_atom_feed)
    end

    it "returns false for an rss feedburner feed" do
      expect(described_class).not_to be_able_to_parse(sample_rss_feed_burner_feed)
    end
  end

  describe "parsing" do
    before do
      @feed = described_class.parse(sample_youtube_atom_feed)
    end

    it "parses the title" do
      expect(@feed.title).to eq "Google"
    end

    it "parses the author" do
      expect(@feed.author).to eq "Google Author"
    end

    it "parses the url" do
      expect(@feed.url).to eq "http://www.youtube.com/user/Google"
    end

    it "parses the feed_url" do
      expect(@feed.feed_url).to eq "http://www.youtube.com/feeds/videos.xml?user=google"
    end

    it "parses the YouTube channel id" do
      expect(@feed.youtube_channel_id).to eq "UCK8sQmJBp8GCxrOtXWBpyEA"
    end
  end
end
