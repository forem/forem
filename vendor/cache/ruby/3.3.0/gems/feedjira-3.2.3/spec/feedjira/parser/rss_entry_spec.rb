# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::RSSEntry do
  before do
    # I don't really like doing it this way because these unit test should only
    # rely on RSSEntry, but this is actually how it should work. You would
    # never just pass entry xml straight to the AtomEnry
    @entry = Feedjira::Parser::RSS.parse(sample_rss_feed).entries.first
    tag = "wfw:commentRss"
    Feedjira::Feed.add_common_feed_entry_element tag, as: :comment_rss
  end

  after do
    # We change the title in one or more specs to test []=
    if @entry.title != "Nokogiri’s Slop Feature"
      feed = Feedjira::Parser::RSS.parse sample_rss_feed
      @entry.title = feed.entries.first.title
    end
  end

  it "parses the title" do
    expect(@entry.title).to eq "Nokogiri’s Slop Feature"
  end

  it "parses the url" do
    expect(@entry.url).to eq "http://tenderlovemaking.com/2008/12/04/nokogiris-slop-feature/"
  end

  it "parses the author" do
    expect(@entry.author).to eq "Aaron Patterson"
  end

  it "parses the content" do
    expect(@entry.content).to eq sample_rss_entry_content
  end

  it "provides a summary" do
    summary = "Oops!  When I released nokogiri version 1.0.7, I totally forgot to talk about Nokogiri::Slop() feature that was added.  Why is it called \"slop\"?  It lets you sloppily explore documents.  Basically, it decorates your document with method_missing() that allows you to search your document via method calls.\nGiven this document:\n\ndoc = Nokogiri::Slop&#40;&#60;&#60;-eohtml&#41;\n&#60;html&#62;\n&#160; &#60;body&#62;\n&#160; [...]"
    expect(@entry.summary).to eq summary
  end

  it "parses the published date" do
    published = Time.parse_safely "Thu Dec 04 17:17:49 UTC 2008"
    expect(@entry.published).to eq published
  end

  it "parses the categories" do
    expect(@entry.categories).to eq %w[computadora nokogiri rails]
  end

  it "parses the guid as id" do
    expect(@entry.id).to eq "http://tenderlovemaking.com/?p=198"
  end

  it "supports each" do
    expect(@entry).to respond_to :each
  end

  it "is able to list out all fields with each" do
    all_fields = []
    title_value = ""
    @entry.each do |field, value|
      all_fields << field
      title_value = value if field == "title"
    end

    expect(title_value).to eq "Nokogiri’s Slop Feature"

    expected_fields = %w[
      author
      categories
      comment_rss
      comments
      content
      entry_id
      published
      summary
      title
      url
    ]
    expect(all_fields.sort).to eq expected_fields
  end

  it "supports checking if a field exists in the entry" do
    expect(@entry).to include "title"
    expect(@entry).to include "author"
  end

  it "allows access to fields with hash syntax" do
    expect(@entry["title"]).to eq "Nokogiri’s Slop Feature"
    expect(@entry["author"]).to eq "Aaron Patterson"
  end

  it "allows setting field values with hash syntax" do
    @entry["title"] = "Foobar"
    expect(@entry.title).to eq "Foobar"
  end

  it "ignores urls from guids with isPermaLink='false'" do
    feed = Feedjira.parse(sample_rss_feed_permalinks)
    expect(feed.entries[0].url).to be_nil
  end

  it "gets urls from guids with isPermaLink='true'" do
    feed = Feedjira.parse(sample_rss_feed_permalinks)
    expect(feed.entries[1].url).to eq "http://example.com/2"
  end

  it "gets urls from guid where isPermaLink is unspecified" do
    feed = Feedjira.parse(sample_rss_feed_permalinks)
    expect(feed.entries[2].url).to eq "http://example.com/3"
  end

  it "prefers urls from <link> when both guid and link are specified" do
    feed = Feedjira.parse(sample_rss_feed_permalinks)
    expect(feed.entries[3].url).to eq "http://example.com/4"
  end

  it "exposes comments URL" do
    feed = Feedjira.parse(sample_rss_feed_with_comments)
    expect(feed.entries[0].comments).to eq "https://news.ycombinator.com/item?id=30937433"
  end
end
