require "rails_helper"

RSpec.describe Feeds::ImportFromXml, type: :service do
  let(:user) { create(:user) }

  let(:feed) { instance_double(Feedjira::Parser::RSS, url: "https://example.com/feed") }
  let(:item) do
    instance_double(
      Feedjira::Parser::RSSEntry,
      title: "Test Article",
      url: "https://example.com/post-1",
      published: Time.current,
      categories: [],
      content: "Article body",
    )
  end

  let(:valid_xml) { "<?xml version='1.0'?><rss></rss>" }

  before do
    allow(Feedjira).to receive(:parse).and_return(feed)
    allow(feed).to receive(:entries).and_return([item])
    allow(Feeds::CheckItemPreviouslyImported).to receive(:call).and_return(false)
    allow(Feeds::AssembleArticleMarkdown).to receive(:call).and_return("---\ntitle: Test Article\n---\n\nBody")
  end

  describe ".call" do
    it "returns error for blank XML" do
      result = described_class.call(xml_content: "", user: user)
      expect(result[:error]).to be_present
    end

    it "returns error when XML exceeds size limit" do
      oversized = "x" * (500.kilobytes + 1)
      result = described_class.call(xml_content: oversized, user: user)
      expect(result[:error]).to be_present
    end

    it "returns error for unparseable XML" do
      allow(Feedjira).to receive(:parse).and_raise(Feedjira::NoParserAvailable)
      result = described_class.call(xml_content: "<not-a-feed/>", user: user)
      expect(result[:error]).to be_present
    end

    it "imports articles and returns count" do
      expect do
        result = described_class.call(xml_content: valid_xml, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(Article, :count).by(1)
    end

    it "skips previously imported items" do
      allow(Feeds::CheckItemPreviouslyImported).to receive(:call).and_return(true)

      result = described_class.call(xml_content: valid_xml, user: user)
      expect(result[:imported]).to eq(0)
    end

    it "creates article with feed attributes" do
      described_class.call(xml_content: valid_xml, user: user)

      article = user.articles.last
      expect(article.feed_source_url).to eq(item.url)
      expect(article.published_from_feed).to be(true)
    end

    it "continues importing remaining items when one fails" do
      item2 = instance_double(
        Feedjira::Parser::RSSEntry,
        title: "Second Article",
        url: "https://example.com/post-2",
        published: Time.current,
        categories: [],
        content: "Body 2",
      )
      allow(feed).to receive(:entries).and_return([item, item2])

      call_count = 0
      allow(Feeds::AssembleArticleMarkdown).to receive(:call) do
        call_count += 1
        raise StandardError, "assembly failed" if call_count == 1

        "---\ntitle: Second Article\n---\n\nBody 2"
      end

      result = described_class.call(xml_content: valid_xml, user: user)
      expect(result[:imported]).to eq(1)
    end
  end
end
