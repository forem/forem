# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Feed do
  describe ".add_common_feed_element" do
    before(:all) do
      described_class.add_common_feed_element("generator")
    end

    it "parses the added element out of Atom feeds" do
      expect(Feedjira.parse(sample_wfw_feed).generator).to eq "TypePad"
    end

    it "parses the added element out of Atom Feedburner feeds" do
      expect(Feedjira::Parser::Atom.new).to respond_to(:generator)
    end

    it "parses the added element out of RSS feeds" do
      expect(Feedjira::Parser::RSS.new).to respond_to(:generator)
    end
  end

  describe ".add_common_feed_elements" do
    before do
      described_class.add_common_feed_elements(:foos)
    end

    it "parses the added element out of Atom feeds" do
      expect(Feedjira.parse(sample_wfw_feed).foos).to eq []
    end

    it "parses the added element out of Atom Feedburner feeds" do
      expect(Feedjira::Parser::Atom.new).to respond_to(:foos)
    end

    it "parses the added element out of RSS feeds" do
      expect(Feedjira::Parser::RSS.new).to respond_to(:foos)
    end
  end

  describe ".add_common_feed_entry_element" do
    before(:all) do
      tag = "wfw:commentRss"
      described_class.add_common_feed_entry_element tag, as: :comment_rss
    end

    it "parses the added element out of Atom feeds entries" do
      entry = Feedjira.parse(sample_wfw_feed).entries.first
      expect(entry.comment_rss).to eq "this is the new val"
    end

    it "parses the added element out of Atom Feedburner feeds entries" do
      expect(Feedjira::Parser::AtomEntry.new).to respond_to(:comment_rss)
    end

    it "parses the added element out of RSS feeds entries" do
      expect(Feedjira::Parser::RSSEntry.new).to respond_to(:comment_rss)
    end
  end

  describe ".add_common_feed_entry_elements" do
    before do
      described_class.add_common_feed_entry_elements(:things)
    end

    it "parses the added element out of Atom feeds entries" do
      entry = Feedjira.parse(sample_wfw_feed).entries.first
      expect(entry.things).to eq []
    end

    it "parses the added element out of Atom Feedburner feeds entries" do
      expect(Feedjira::Parser::AtomEntry.new).to respond_to(:things)
    end

    it "parses the added element out of RSS feeds entries" do
      expect(Feedjira::Parser::RSSEntry.new).to respond_to(:things)
    end
  end
end
