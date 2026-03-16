require "rails_helper"

RSpec.describe Feeds::AssembleArticleMarkdown, type: :service do
  let(:user) do
    create(:user).tap do |u|
      u.setting.update(feed_mark_canonical: true)
    end
  end
  let(:feed_source_url) { "https://feed.source/url" }
  let(:feed) { instance_double(Feedjira::Parser::RSS, url: "https://feed.source/") }
  let(:title) { "A title" }
  let(:content) { "Some content that came in with the item, should be the body" }

  let(:item) do
    instance_double(
      Feedjira::Parser::RSSEntry,
      title: title,
      categories: %w[tag1 tag2 tag3 tag4 tag5],
      published: "2020-12-20",
      content: content,
      url: "https://feed.source",
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

  context "when content is HTML" do
    let(:content) { "<p>First paragraph.</p><p>Second paragraph.</p><h2>A heading</h2><p>More text.</p>" }

    it "converts HTML to markdown" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("First paragraph.")
      expect(body).to include("## A heading")
    end
  end

  context "when content is markdown (no HTML block tags)" do
    let(:content) do
      "### A Heading\n\nSome paragraph text here.\n\n* bullet one\n* bullet two\n\nAnother paragraph."
    end

    it "preserves the markdown formatting as-is" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("### A Heading")
      expect(body).to include("* bullet one\n* bullet two")
      expect(body).to include("Another paragraph.")
    end
  end

  context "when content is plain text with no formatting" do
    let(:content) { "Just some plain text content from a feed." }

    it "includes the plain text directly" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("Just some plain text content from a feed.")
    end
  end

  context "when content is markdown with inline HTML (img tags)" do
    let(:content) do
      "### Title\n\nSome text with an image:\n\n<img src=\"https://example.com/img.png\">\n\nMore text."
    end

    it "preserves the markdown and inline HTML" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("### Title")
      expect(body).to include("<img src=\"https://example.com/img.png\">")
    end
  end

  context "when markdown content has relative image URLs" do
    let(:content) do
      "### Post\n\n<img src=\"/content/blog/image.png\">\n\nMore text."
    end

    it "resolves relative img src to absolute URLs" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("<img src=\"https://feed.source/content/blog/image.png\">")
      expect(body).not_to include("src=\"/content")
    end
  end

  context "when markdown content has relative markdown image syntax" do
    let(:content) do
      "### Post\n\n![screenshot](/images/screenshot.png)\n\nMore text."
    end

    it "resolves relative markdown images to absolute URLs" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("![screenshot](https://feed.source/images/screenshot.png)")
    end
  end

  context "when content is markdown with some inline HTML block tags" do
    let(:content) do
      <<~MARKDOWN
        ### A Heading

        Some paragraph text here.

        Another paragraph with more text.

        <p style="text-align: center"><a href="https://example.com">link</a></p>

        ![](/images/photo.png)

        More markdown text after the HTML.
      MARKDOWN
    end

    it "treats as markdown and preserves formatting" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("### A Heading")
      expect(body).to include("Some paragraph text here.")
      expect(body).to include("More markdown text after the HTML.")
    end

    it "resolves relative image URLs" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("![](https://feed.source/images/photo.png)")
    end
  end

  context "when content is nil" do
    let(:item) do
      instance_double(
        Feedjira::Parser::RSSEntry,
        title: title,
        categories: %w[tag1 tag2],
        published: "2020-12-20",
        content: nil,
        summary: nil,
        url: "https://feed.source",
      )
    end

    it "handles nil content gracefully" do
      body = feeds_assemble_article_markdown.call

      expect(body).to include("title: A title")
    end
  end
end
