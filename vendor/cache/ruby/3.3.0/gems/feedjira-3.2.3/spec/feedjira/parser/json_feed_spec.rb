# frozen_string_literal: true

require "spec_helper"

module Feedjira
  module Parser
    describe ".able_to_parse?" do
      it "returns true for a JSON feed" do
        expect(JSONFeed).to be_able_to_parse(sample_json_feed)
      end

      it "returns false for an RSS feed" do
        expect(JSONFeed).not_to be_able_to_parse(sample_rss_feed)
      end

      it "returns false for an Atom feed" do
        expect(JSONFeed).not_to be_able_to_parse(sample_atom_feed)
      end
    end

    describe "parsing" do
      before do
        @feed = JSONFeed.parse(sample_json_feed)
      end

      it "parses the version" do
        expect(@feed.version).to eq "https://jsonfeed.org/version/1"
      end

      it "parses the title" do
        expect(@feed.title).to eq "inessential.com"
      end

      it "parses the url" do
        expect(@feed.url).to eq "http://inessential.com/"
      end

      it "parses the feed_url" do
        expect(@feed.feed_url).to eq "http://inessential.com/feed.json"
      end

      it "parses the description" do
        expect(@feed.description).to eq "Brent Simmons’s weblog."
      end

      it "parses the favicon" do
        expect(@feed.favicon).to eq "http://inessential.com/favicon.ico"
      end

      it "parses the icon" do
        expect(@feed.icon).to eq "http://inessential.com/icon.png"
      end

      it "parses the language" do
        expect(@feed.language).to eq "en-US"
      end

      it "parses expired and return default (nil)" do
        expect(@feed.expired).to be_nil
      end

      it "parses entries" do
        expect(@feed.entries.size).to eq 20
      end
    end
  end
end
