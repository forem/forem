require "rails_helper"

RSpec.describe Feeds::AssembleArticleMarkdown, type: :service do
  let(:user) do
    u = create(:user)
    u.setting.update(feed_mark_canonical: true)
    u
  end
  let(:feed_source_url) { "https://feed.source/url" }
  let(:feed) { instance_double("Feedjira::Parser::RSS", url: "https://feed.source/") }
  let(:title) { "A title" }
  let(:content) { "Some content that came in with the item, should be the body" }

  let(:item) do
    instance_double(
      "Feedjira::Parser::RSSEntry",
      title: title,
      categories: %w[tag1 tag2 tag3 tag4 tag5],
      published: "2020-12-20",
      content: content,
    )
  end

  let(:feeds_assemble_article_markdown) { described_class.new(item, user, feed, feed_source_url) }

  it "creates markdown head matter" do
    body = feeds_assemble_article_markdown.call

    expect(body).to include("title: A title")
    expect(body).to include("date: 2020-12-20")
  end

  it "includes the content from the feed" do
    body = feeds_assemble_article_markdown.call

    expect(body).to include(content)
  end

  context "when item has a long title" do
    let(:title) { "Words " * 25 }

    it "limits the title to 128 characters by truncation" do
      body = feeds_assemble_article_markdown.call

      title_line = body.lines.detect { |line| line.starts_with?("title:") }
      shortened_title = title_line.split(":").second.strip
      # we expect 21 "Words" plus an ellipsis, total of 128 characters
      expected_title = "Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words Words..." # rubocop:disable Layout/LineLength

      expect(shortened_title.size).to eq(128)
      expect(shortened_title).to eq(expected_title)
    end
  end
end
