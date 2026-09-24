require "rails_helper"

RSpec.describe Feeds::ImportFromXml, type: :service do
  let(:user) { create(:user) }

  let(:valid_rss_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Engineering Blog</title>
          <link>https://example.com</link>
          <description>Insights from engineering</description>
          <item>
            <title>Scaling PostgreSQL with pgvector</title>
            <link>https://example.com/posts/scaling-postgres?source=rss</link>
            <description><![CDATA[<p>Here is how we optimized our vector database queries.</p>]]></description>
            <pubDate>Mon, 15 Jan 2024 10:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
    XML
  end

  let(:valid_atom_xml) do
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Architecture Journal</title>
        <link href="https://example.org/feed" rel="self"/>
        <link href="https://example.org"/>
        <updated>2024-02-01T12:00:00Z</updated>
        <id>https://example.org/</id>
        <entry>
          <title>Modern Event Architecture</title>
          <link href="https://example.org/posts/event-architecture"/>
          <id>https://example.org/posts/event-architecture</id>
          <updated>2024-02-01T12:00:00Z</updated>
          <content type="html"><![CDATA[<p>Event-driven pipelines in distributed systems.</p>]]></content>
        </entry>
      </feed>
    XML
  end

  let(:malformed_xml) { "<<<not-valid-xml>>><>>" }

  def build_feed_xml(item_count)
    items = (1..item_count).map do |i|
      <<~ITEM
        <item>
          <title>Post #{i}</title>
          <link>https://example.com/post-#{i}</link>
          <description><![CDATA[<p>Content #{i}</p>]]></description>
        </item>
      ITEM
    end.join("\n")

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Feed with #{item_count} items</title>
          <link>https://example.com</link>
          <description>Testing boundaries</description>
          #{items}
        </channel>
      </rss>
    XML
  end

  describe ".call" do
    it "returns error for blank XML" do
      result = described_class.call(xml_content: "", user: user)
      expect(result[:error]).to eq(I18n.t("feeds.xml_imports.blank"))
    end

    it "returns error when XML exceeds size limit" do
      oversized = "x" * (500.kilobytes + 1)
      result = described_class.call(xml_content: oversized, user: user)
      expect(result[:error]).to eq(I18n.t("feeds.xml_imports.too_large"))
    end

    it "returns error when feed has no entries" do
      empty_feed = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Empty Blog</title>
            <link>https://example.com</link>
            <description>No entries</description>
          </channel>
        </rss>
      XML

      result = described_class.call(xml_content: empty_feed, user: user)
      expect(result[:error]).to eq(I18n.t("feeds.xml_imports.no_entries"))
    end

    it "succeeds and imports all entries when feed has exactly 25 items (boundary value)" do
      boundary_feed_25 = build_feed_xml(25)

      expect do
        result = described_class.call(xml_content: boundary_feed_25, user: user)
        expect(result[:error]).to be_nil
        expect(result[:imported]).to eq(25)
      end.to change(user.articles, :count).by(25)
    end

    it "fails validation, imports 0 articles, and returns error when feed has 26 items" do
      boundary_feed_26 = build_feed_xml(26)

      expect do
        result = described_class.call(xml_content: boundary_feed_26, user: user)
        expect(result[:error]).to eq(I18n.t("feeds.xml_imports.too_many_entries", max: 25))
        expect(result[:imported]).to be_nil
      end.not_to change(user.articles, :count)
    end

    it "safely processes entries containing raw HTML, script tags, and malicious attributes without crashing" do
      xss_feed_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Security Test Blog</title>
            <link>https://example.com</link>
            <description>Testing XSS sanitization</description>
            <item>
              <title>XSS Injection Attempt &lt;script&gt;alert('title-xss')&lt;/script&gt;</title>
              <link>https://example.com/posts/xss-test</link>
              <description><![CDATA[
                <p>Normal introductory text.</p>
                <script>alert('xss')</script>
                <img src="x" onerror="alert('img-xss')"/>
                <a href="javascript:alert('link-xss')">Click me</a>
                <p>Closing text.</p>
              ]]></description>
              <pubDate>Mon, 15 Jan 2024 10:00:00 GMT</pubDate>
            </item>
          </channel>
        </rss>
      XML

      expect do
        result = described_class.call(xml_content: xss_feed_xml, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(user.articles, :count).by(1)

      article = user.articles.last
      expect(article.published_from_feed).to be(true)
      expect(article.published).to be(false)
      expect(article.body_markdown).to be_present
    end

    it "parses valid RSS 2.0 XML end-to-end and persists article" do
      expect do
        result = described_class.call(xml_content: valid_rss_xml, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(user.articles, :count).by(1)

      article = user.articles.last
      expect(article.title).to eq("Scaling PostgreSQL with pgvector")
      expect(article.feed_source_url).to eq("https://example.com/posts/scaling-postgres")
      expect(article.published_from_feed).to be(true)
      expect(article.show_comments).to be(true)
    end

    it "parses valid Atom XML end-to-end and persists article" do
      expect do
        result = described_class.call(xml_content: valid_atom_xml, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(user.articles, :count).by(1)

      article = user.articles.last
      expect(article.title).to eq("Modern Event Architecture")
      expect(article.feed_source_url).to eq("https://example.org/posts/event-architecture")
      expect(article.published_from_feed).to be(true)
      expect(article.show_comments).to be(true)
    end

    it "creates a NotificationSubscription for the author on import" do
      described_class.call(xml_content: valid_rss_xml, user: user)

      article = user.articles.last
      subscription = NotificationSubscription.find_by(
        user: user,
        notifiable_id: article.id,
        notifiable_type: "Article",
        config: "all_comments",
      )
      expect(subscription).to be_present
    end

    it "skips previously imported items without duplicate creation" do
      described_class.call(xml_content: valid_rss_xml, user: user)

      expect do
        result = described_class.call(xml_content: valid_rss_xml, user: user)
        expect(result[:imported]).to eq(0)
      end.not_to change(user.articles, :count)
    end

    it "skips Medium comment replies via Feeds::CheckItemMediumReply" do
      allow(Feeds::CheckItemMediumReply).to receive(:call).and_return(true)

      expect do
        result = described_class.call(xml_content: valid_rss_xml, user: user)
        expect(result[:imported]).to eq(0)
      end.not_to change(user.articles, :count)
    end

    it "handles entries with missing or nil title and url gracefully" do
      xml_with_bad_entry = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Blog</title>
            <link>https://example.com</link>
            <description>Blog</description>
            <item>
              <description><![CDATA[<p>No title or link</p>]]></description>
            </item>
            <item>
              <title>Valid Post</title>
              <link>https://example.com/posts/valid-post</link>
              <description><![CDATA[<p>Valid content</p>]]></description>
            </item>
          </channel>
        </rss>
      XML

      expect do
        result = described_class.call(xml_content: xml_with_bad_entry, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(user.articles, :count).by(1)
    end

    it "logs a warning and returns error when XML syntax is invalid" do
      allow(Rails.logger).to receive(:warn)

      result = described_class.call(xml_content: malformed_xml, user: user)
      expect(result[:error]).to eq(I18n.t("feeds.xml_imports.invalid_xml"))
      expect(Rails.logger).to have_received(:warn).with(a_string_including("Feeds::ImportFromXml parse error"))
    end

    it "rescues StandardError during Feedjira parsing, logs a warning, and returns error" do
      allow(Feedjira).to receive(:parse).and_raise(StandardError, "unexpected parser failure")
      allow(Rails.logger).to receive(:warn)

      result = described_class.call(xml_content: valid_rss_xml, user: user)
      expect(result[:error]).to eq(I18n.t("feeds.xml_imports.invalid_xml"))
      expect(Rails.logger).to have_received(:warn).with(a_string_including("StandardError - unexpected parser failure"))
    end

    it "continues importing remaining items when one item fails to assemble or create" do
      two_items_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Blog</title>
            <link>https://example.com</link>
            <description>Blog</description>
            <item>
              <title>First Post</title>
              <link>https://example.com/posts/first</link>
              <description><![CDATA[<p>Content 1</p>]]></description>
            </item>
            <item>
              <title>Second Post</title>
              <link>https://example.com/posts/second</link>
              <description><![CDATA[<p>Content 2</p>]]></description>
            </item>
          </channel>
        </rss>
      XML

      call_count = 0
      allow(Feeds::AssembleArticleMarkdown).to receive(:call) do |item, _user, _feed, _url|
        call_count += 1
        raise StandardError, "assembly failure" if call_count == 1

        "---\ntitle: #{item.title}\n---\n\nBody"
      end

      expect do
        result = described_class.call(xml_content: two_items_xml, user: user)
        expect(result[:imported]).to eq(1)
      end.to change(user.articles, :count).by(1)
    end
  end
end
