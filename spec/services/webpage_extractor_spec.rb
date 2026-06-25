require "rails_helper"

RSpec.describe WebpageExtractor do
  describe ".extract" do
    it "extracts a single valid URL" do
      article = double("Article", body_markdown: "Check this out: https://example.com/test")
      expect(described_class.extract(article)).to eq(["https://example.com/test"])
    end

    it "extracts multiple distinct URLs" do
      markdown = <<~MD
        Here is [a link](https://example.com/page1).
        And [another](https://test.com).
        Repeated: https://example.com/page1
      MD
      article = double("Article", body_markdown: markdown)
      expect(described_class.extract(article)).to match_array(["https://example.com/page1", "https://test.com"])
    end

    it "ignores URLs inside fenced codeblocks" do
      markdown = <<~MD
        Check out this snippet:
        ```ruby
        # Don't extract this:
        url = "https://example.com/codeblock"
        ```
        But extract this: https://example.com/valid
      MD
      article = double("Article", body_markdown: markdown)
      expect(described_class.extract(article)).to eq(["https://example.com/valid"])
    end

    it "ignores URLs inside inline code blocks" do
      markdown = "Please use `https://example.com/inline` to fetch the data, not https://example.com/valid."
      article = double("Article", body_markdown: markdown)
      expect(described_class.extract(article)).to eq(["https://example.com/valid"])
    end

    it "ignores URLs inside Liquid tags" do
      markdown = <<~MD
        Look at this embed:
        {% embed https://example.com/embed %}
        But check this one out: https://example.com/valid
      MD
      article = double("Article", body_markdown: markdown)
      expect(described_class.extract(article)).to eq(["https://example.com/valid"])
    end

    it "trims trailing punctuation from URLs" do
      markdown = <<~MD
        Have you seen https://example.com/page1?
        Or maybe https://example.com/page2.
        What about https://example.com/page3!
        I also like https://example.com/page4, which is cool.
        And https://example.com/page5; very nice.
        Look here: https://example.com/page6:
      MD
      article = double("Article", body_markdown: markdown)
      expected_urls = (1..6).map { |i| "https://example.com/page#{i}" }
      expect(described_class.extract(article)).to match_array(expected_urls)
    end

    it "returns an empty array if the record does not respond to body_markdown" do
      record = double("User")
      expect(described_class.extract(record)).to eq([])
    end

    it "returns an empty array if body_markdown is blank" do
      article = double("Article", body_markdown: "")
      expect(described_class.extract(article)).to eq([])
    end
  end
end
