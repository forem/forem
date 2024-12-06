# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::AtomFeedBurnerEntry do
  before do
    Feedjira::Parser::AtomFeedBurner.preprocess_xml = false
    # I don't really like doing it this way because these unit test should only
    # rely on AtomEntry, but this is actually how it should work. You would
    # never just pass entry xml straight to the AtomEnry
    feed = Feedjira::Parser::AtomFeedBurner.parse sample_feedburner_atom_feed
    @entry = feed.entries.first
  end

  it "parses the title" do
    expect(@entry.title).to eq "Making a Ruby C library even faster"
  end

  it "is able to fetch a url via the 'alternate' rel if no origLink exists" do
    xml = File.read("#{File.dirname(__FILE__)}/../../sample_feeds/PaulDixExplainsNothingAlternate.xml")
    entry = Feedjira::Parser::AtomFeedBurner.parse(xml).entries.first
    expect(entry.url).to eq("http://feeds.feedburner.com/~r/PaulDixExplainsNothing/~3/519925023/making-a-ruby-c-library-even-faster.html")
  end

  it "parses the url" do
    expect(@entry.url).to eq "http://www.pauldix.net/2009/01/making-a-ruby-c-library-even-faster.html"
  end

  it "parses the url when there is no alternate" do
    xml = File.read("#{File.dirname(__FILE__)}/../../sample_feeds/FeedBurnerUrlNoAlternate.xml")
    entry = Feedjira::Parser::AtomFeedBurner.parse(xml).entries.first
    expect(entry.url).to eq "http://example.com/QQQQ.html"
  end

  it "parses the author" do
    expect(@entry.author).to eq "Paul Dix"
  end

  it "parses the content" do
    expect(@entry.content).to eq sample_feedburner_atom_entry_content
  end

  it "provides a summary" do
    summary = "Last week I released the first version of a SAX based XML parsing library called SAX-Machine. It uses Nokogiri, which uses libxml, so it's pretty fast. However, I felt that it could be even faster. The only question was how..."
    expect(@entry.summary).to eq summary
  end

  it "parses the published date" do
    published = Time.parse_safely "Thu Jan 22 15:50:22 UTC 2009"
    expect(@entry.published).to eq published
  end

  it "parses the categories" do
    expect(@entry.categories).to eq ["Ruby", "Another Category"]
  end
end
