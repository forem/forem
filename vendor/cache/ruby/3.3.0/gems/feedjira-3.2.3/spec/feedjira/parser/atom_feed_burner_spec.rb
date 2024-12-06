# frozen_string_literal: true

require "spec_helper"

module Feedjira
  module Parser
    describe "#will_parse?" do
      it "returns true for a feedburner atom feed" do
        expect(AtomFeedBurner).to be_able_to_parse(sample_feedburner_atom_feed)
      end

      it "returns false for an rdf feed" do
        expect(AtomFeedBurner).not_to be_able_to_parse(sample_rdf_feed)
      end

      it "returns false for a regular atom feed" do
        expect(AtomFeedBurner).not_to be_able_to_parse(sample_atom_feed)
      end

      it "returns false for an rss feedburner feed" do
        expect(AtomFeedBurner).not_to be_able_to_parse sample_rss_feed_burner_feed
      end
    end

    describe "parsing old style feeds" do
      before do
        @feed = AtomFeedBurner.parse(sample_feedburner_atom_feed)
      end

      it "parses the title" do
        expect(@feed.title).to eq "Paul Dix Explains Nothing"
      end

      it "parses the description" do
        description = "Entrepreneurship, programming, software development, politics, NYC, and random thoughts."
        expect(@feed.description).to eq description
      end

      it "parses the url" do
        expect(@feed.url).to eq "http://www.pauldix.net/"
      end

      it "parses the feed_url" do
        expect(@feed.feed_url).to eq "http://feeds.feedburner.com/PaulDixExplainsNothing"
      end

      it "parses no hub urls" do
        expect(@feed.hubs.count).to eq 0
      end

      it "parses hub urls" do
        AtomFeedBurner.preprocess_xml = false
        feed_with_hub = AtomFeedBurner.parse(load_sample("TypePadNews.xml"))
        expect(feed_with_hub.hubs.count).to eq 1
      end

      it "parses entries" do
        expect(@feed.entries.size).to eq 5
      end

      it "changes url" do
        new_url = "http://some.url.com"
        expect { @feed.url = new_url }.not_to raise_error
        expect(@feed.url).to eq new_url
      end

      it "changes feed_url" do
        new_url = "http://some.url.com"
        expect { @feed.feed_url = new_url }.not_to raise_error
        expect(@feed.feed_url).to eq new_url
      end
    end

    describe "parsing alternate style feeds" do
      before do
        @feed = AtomFeedBurner.parse(sample_feedburner_atom_feed_alternate)
      end

      it "parses the title" do
        expect(@feed.title).to eq "Giant Robots Smashing Into Other Giant Robots"
      end

      it "parses the description" do
        description = "Written by thoughtbot"
        expect(@feed.description).to eq description
      end

      it "parses the url" do
        expect(@feed.url).to eq "https://robots.thoughtbot.com"
      end

      it "parses the feed_url" do
        expect(@feed.feed_url).to eq "http://feeds.feedburner.com/GiantRobotsSmashingIntoOtherGiantRobots"
      end

      it "parses hub urls" do
        expect(@feed.hubs.count).to eq 1
      end

      it "parses entries" do
        expect(@feed.entries.size).to eq 3
      end

      it "changes url" do
        new_url = "http://some.url.com"
        expect { @feed.url = new_url }.not_to raise_error
        expect(@feed.url).to eq new_url
      end

      it "changes feed_url" do
        new_url = "http://some.url.com"
        expect { @feed.feed_url = new_url }.not_to raise_error
        expect(@feed.feed_url).to eq new_url
      end
    end

    describe "preprocessing" do
      it "retains markup in xhtml content" do
        AtomFeedBurner.preprocess_xml = true

        feed = AtomFeedBurner.parse sample_feed_burner_atom_xhtml_feed
        entry = feed.entries.first

        expect(entry.content).to match(/\A<p/)
      end
    end
  end
end
