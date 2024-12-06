# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::JSONFeedItem do
  before do
    # I don't really like doing it this way because these unit test should only
    # rely on JSONFeed, but this is actually how it should work. You would
    # never just pass entry json straight to the JSONFeedItem
    @entry = Feedjira::Parser::JSONFeed.parse(sample_json_feed).entries.first
  end

  it "parses the id" do
    expect(@entry.id).to eq "http://inessential.com/2017/06/02/james_dempsey_and_the_breakpoints_benefi"
  end

  it "parses the url" do
    expect(@entry.url).to eq "http://inessential.com/2017/06/02/james_dempsey_and_the_breakpoints_benefi"
  end

  it "parses the title" do
    expect(@entry.title).to eq "James Dempsey and the Breakpoints Benefit App Camp for Girls"
  end

  it "parses the content" do
    content = "<p>On Wednesday night I know where I’ll be — playing keyboard for a few songs at the James Dempsey and the Breakpoints concert benefitting App Camp for Girls.</p>\n\n<p><a href=\"https://www.classy.org/events/-/e126329\">You should get tickets</a>. It’s a fun time for a great cause.</p>\n\n<p>Bonus: James writes about how <a href=\"http://jamesdempsey.net/2017/06/02/wwdc-in-san-jose-full-circle/\">this concert is full circle for him</a>. It’s a special night.</p>"
    expect(@entry.content).to eq content
  end

  it "parses the published date" do
    published = Time.parse_safely "2017-06-02T22:05:47-07:00"
    expect(@entry.published).to eq published
  end

  it "supports each" do
    expect(@entry).to respond_to :each
  end

  it "is able to list out all the fields with each" do
    all_fields = []
    title_value = ""
    @entry.each do |field, value|
      all_fields << field
      title_value = value if field == "title"
    end

    expect(title_value).to eq "James Dempsey and the Breakpoints Benefit App Camp for Girls"

    expected_fields = %w[
      author
      banner_image
      categories
      content
      entry_id
      external_url
      image
      json
      published
      summary
      title
      updated
      url
    ]
    expect(all_fields).to match_array expected_fields
  end

  it "supports checking if a field exists in the entry" do
    expect(@entry).to include "title"
    expect(@entry).to include "url"
  end

  it "allows access to fields with hash syntax" do
    expect(@entry["title"]).to eq "James Dempsey and the Breakpoints Benefit App Camp for Girls"
    expect(@entry["url"]).to eq "http://inessential.com/2017/06/02/james_dempsey_and_the_breakpoints_benefi"
  end

  it "allows setting field values with hash syntax" do
    @entry["title"] = "Foobar"
    expect(@entry.title).to eq "Foobar"
  end
end
