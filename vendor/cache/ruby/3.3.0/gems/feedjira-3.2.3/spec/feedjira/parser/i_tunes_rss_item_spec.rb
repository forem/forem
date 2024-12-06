# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::ITunesRSSItem do
  before do
    # I don't really like doing it this way because these unit test should only
    # rely on ITunesRssItem, but this is actually how it should work. You would
    # never just pass entry xml straight to the ITunesRssItem
    @item = Feedjira::Parser::ITunesRSS.parse(sample_itunes_feed).entries.first
  end

  it "parses the title" do
    expect(@item.title).to eq "Shake Shake Shake Your Spices"
  end

  it "parses the itunes title" do
    expect(@item.itunes_title).to eq "Shake Shake Shake Your Spices"
  end

  it "parses the author" do
    expect(@item.itunes_author).to eq "John Doe"
  end

  it "parses the subtitle" do
    expect(@item.itunes_subtitle).to eq "A short primer on table spices"
  end

  it "parses the summary" do
    summary = "This week we talk about salt and pepper shakers, comparing and contrasting pour rates, construction materials, and overall aesthetics. Come and join the party!"
    expect(@item.itunes_summary).to eq summary
  end

  it "parses the itunes season" do
    expect(@item.itunes_season).to eq "1"
  end

  it "parses the itunes episode number" do
    expect(@item.itunes_episode).to eq "3"
  end

  it "parses the itunes episode type" do
    expect(@item.itunes_episode_type).to eq "full"
  end

  it "parses the enclosure" do
    expect(@item.enclosure_length).to eq "8727310"
    expect(@item.enclosure_type).to eq "audio/x-m4a"
    expect(@item.enclosure_url).to eq "http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4a"
  end

  it "parses the guid as id" do
    expect(@item.id).to eq "http://example.com/podcasts/archive/aae20050615.m4a"
  end

  it "parses the published date" do
    published = Time.parse_safely "Wed Jun 15 19:00:00 UTC 2005"
    expect(@item.published).to eq published
  end

  it "parses the duration" do
    expect(@item.itunes_duration).to eq "7:04"
  end

  it "parses the keywords" do
    expect(@item.itunes_keywords).to eq "salt, pepper, shaker, exciting"
  end

  it "parses the image" do
    expect(@item.itunes_image).to eq "http://example.com/podcasts/everything/AllAboutEverything.jpg"
  end

  it "parses the order" do
    expect(@item.itunes_order).to eq "12"
  end

  it "parses the closed captioned flag" do
    expect(@item.itunes_closed_captioned).to eq "yes"
  end

  it "parses the encoded content" do
    content = "<p><strong>TOPIC</strong>: Gooseneck Options</p>"
    expect(@item.content).to eq content
  end
end
