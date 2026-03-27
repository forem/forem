require "rails_helper"

RSpec.describe LiquidEmbedExtractor do
  describe ".extract" do
    it "returns an empty array if the record has no markdown" do
      comment = create(:comment, body_markdown: "empty")
      comment.update_column(:body_markdown, "") # Bypass presence Validation
      expect(described_class.extract(comment)).to eq([])
    end

    it "extracts standard liquid tags accurately" do
      body = <<~MARKDOWN
        Hey check out these videos!
        {% youtube dQw4w9WgXcQ %}
        {% twitter 1234567890 %}
      MARKDOWN
      
      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      # NOTE: TweetTag registers as 'tweet' internally.
      expect(data).to contain_exactly(
        { tag_name: "youtube", url: "dQw4w9WgXcQ", options: "dQw4w9WgXcQ", referenced_type: nil, referenced_id: nil },
        { tag_name: "tweet", url: "1234567890", options: "1234567890", referenced_type: nil, referenced_id: nil }
      )
    end

    it "correctly delegates UnifiedEmbed links into their normalized class trackers" do
      body = <<~MARKDOWN
        {% embed https://youtube.com/watch?v=dQw4w9WgXcQ %}
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      expect(data).to contain_exactly(
        { tag_name: "youtube", url: "dQw4w9WgXcQ", options: "https://youtube.com/watch?v=dQw4w9WgXcQ", referenced_type: nil, referenced_id: nil }
      )
    end

    it "captures internal explicit Ruby ApplicationRecord instances into polymorphic references sequentially" do
      # UserTag explicitly scopes User objects from records
      user_record = create(:user, username: "benhalpern")
      
      body = <<~MARKDOWN
        {% user benhalpern %}
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      expect(data).to contain_exactly(
        { tag_name: "user", url: "benhalpern", options: "benhalpern", referenced_type: "User", referenced_id: user_record.id }
      )
    end

    it "correctly resolves internal DEV Article links wrapped in general UnifiedEmbeds into native polymorphic relationships" do
      dev_article = create(:article, title: "Test Article")
      dev_article.user.update!(username: "testuser")
      
      domain = Settings::General.app_domain || "localhost:3000"
      article_url = "http://#{domain}/testuser/#{dev_article.slug}"

      stub_request(:head, article_url).to_return(status: 200, body: "", headers: {})
      stub_request(:get, article_url).to_return(status: 200, body: "<html><head></head><body>Example</body></html>", headers: {})

      body = <<~MARKDOWN
        {% embed #{article_url} %}
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      expect(data).to contain_exactly(
        { tag_name: "link", url: article_url, options: article_url, referenced_type: "Article", referenced_id: dev_article.id }
      )
    end

    it "correctly resolves direct Comment tags into native polymorphic relationships" do
      target_comment = create(:comment)
      
      body = <<~MARKDOWN
        {% comment #{target_comment.id_code} %}
      MARKDOWN

      parent = create(:comment, body_markdown: body)
      data = described_class.extract(parent)

      expect(data).to contain_exactly(
        { tag_name: "comment", url: target_comment.id_code, options: target_comment.id_code, referenced_type: "Comment", referenced_id: target_comment.id }
      )
    end

    it "correctly resolves general fallback URL embeds via OpenGraph mappings natively" do
      stub_request(:head, "https://example.com/unsupported-embed")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://example.com/unsupported-embed")
        .to_return(status: 200, body: "<html><head></head><body>Example</body></html>", headers: {})

      body = <<~MARKDOWN
        {% embed https://example.com/unsupported-embed %}
      MARKDOWN

      parent = create(:comment, body_markdown: body)
      data = described_class.extract(parent)

      expect(data).to contain_exactly(
        { tag_name: "open_graph", url: "https://example.com/unsupported-embed", options: "https://example.com/unsupported-embed", referenced_type: nil, referenced_id: nil }
      )
    end
  end
end
