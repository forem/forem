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

      # NOTE: Historically TweetTag registered as 'tweet', but regex matches raw 'twitter'.
      expect(data).to contain_exactly(
        { tag_name: "youtube", url: "dQw4w9WgXcQ", options: "dQw4w9WgXcQ", referenced_type: nil, referenced_id: nil },
        { tag_name: "twitter", url: "1234567890", options: "1234567890", referenced_type: nil, referenced_id: nil },
      )
    end

    it "correctly delegates UnifiedEmbed links into their normalized class trackers" do
      body = <<~MARKDOWN
        {% embed https://youtube.com/watch?v=dQw4w9WgXcQ %}
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      # The raw URL remains assigned to embed inherently bypassing ActionView.
      expect(data).to contain_exactly(
        { tag_name: "embed", url: "https://youtube.com/watch?v=dQw4w9WgXcQ",
          options: "https://youtube.com/watch?v=dQw4w9WgXcQ", referenced_type: nil, referenced_id: nil },
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
        { tag_name: "user", url: "benhalpern", options: "benhalpern", referenced_type: "User",
          referenced_id: user_record.id },
      )
    end

    it "correctly captures org_posts and explicit organization Liquid Tags into polymorphic references sequentially" do
      org = create(:organization, slug: "test_org")

      body = <<~MARKDOWN
        {% organization test_org %}
        {% org_posts test_org %}
      MARKDOWN

      article = create(:article)
      article.update_column(:body_markdown, body)
      data = described_class.extract(article)

      expect(data).to contain_exactly(
        { tag_name: "organization", url: "test_org", options: "test_org", referenced_type: "Organization",
          referenced_id: org.id },
        { tag_name: "org_posts", url: "test_org", options: "test_org", referenced_type: "Organization",
          referenced_id: org.id },
      )
    end

    it "resolves internal DEV Article links wrapped in UnifiedEmbeds into polymorphic relationships" do
      user = create(:user, username: "testuser")
      dev_article = create(:article, user: user, title: "Test Article")

      domain = Settings::General.app_domain || "localhost:3000"
      article_url = "http://#{domain}/testuser/#{dev_article.slug}"

      stub_request(:head, article_url).to_return(status: 200, body: "", headers: {})
      stub_request(:get, article_url).to_return(status: 200, body: "<html><head></head><body>Example</body></html>",
                                                headers: {})

      body = <<~MARKDOWN
        {% embed #{article_url} %}
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      data = described_class.extract(comment)

      expect(data).to contain_exactly(
        { tag_name: "embed", url: article_url, options: article_url, referenced_type: "Article",
          referenced_id: dev_article.id },
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
        { tag_name: "comment", url: target_comment.id_code, options: target_comment.id_code,
          referenced_type: "Comment", referenced_id: target_comment.id },
      )
    end

    it "correctly resolves general fallback URL embeds bypassing native OpenGraph mappings securely" do
      stub_request(:head, "https://example.com/unsupported-embed").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://example.com/unsupported-embed").to_return(
        status: 200,
        body: "<html><head></head><body>Example</body></html>",
        headers: {},
      )

      body = <<~MARKDOWN
        {% embed https://example.com/unsupported-embed %}
      MARKDOWN

      parent = create(:comment, body_markdown: body)
      data = described_class.extract(parent)

      expect(data).to contain_exactly(
        { tag_name: "embed", url: "https://example.com/unsupported-embed",
          options: "https://example.com/unsupported-embed", referenced_type: nil, referenced_id: nil },
      )
    end

    it "batches reference resolution queries by tag type and skips tags inside codeblocks" do
      user1 = create(:user, username: "alice_embed")
      user2 = create(:user, username: "bob_embed")

      body = <<~MARKDOWN
        {% user alice_embed %}
        {% user bob_embed %}
        {% user alice_embed %}
        ```
        {% user ignored_fenced_user %}
        ```
        Inline `{% user ignored_inline_user %}` tag.
      MARKDOWN

      comment = create(:comment, body_markdown: body)
      user_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        user_queries << sql if sql.include?('"users"') && !payload[:cached]
      end

      data = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.extract(comment)
      end

      expect(data).to eq(
        [
          {
            tag_name: "user",
            url: "alice_embed",
            options: "alice_embed",
            referenced_type: "User",
            referenced_id: user1.id
          },
          {
            tag_name: "user",
            url: "bob_embed",
            options: "bob_embed",
            referenced_type: "User",
            referenced_id: user2.id
          },
        ],
      )
      expect(user_queries.size).to eq(1)
    end

    it "resolves {% link %} and {% post %} tags for both user and organization articles (including legacy org slugs)" do
      user = create(:user, username: "linkauthor")
      user_article = create(:article, user: user)
      org = create(:organization, slug: "currentorg")
      org.update_columns(old_slug: "legacyorg")
      org_article = create(:article, organization: org)
      domain = Settings::General.app_domain || "localhost:3000"

      body = <<~MARKDOWN
        {% link /linkauthor/#{user_article.slug} %}
        {% post http://#{domain}/currentorg/#{org_article.slug} %}
        {% link legacyorg/#{org_article.slug} %}
      MARKDOWN

      holder = create(:article)
      holder.update_column(:body_markdown, body)
      data = described_class.extract(holder)

      expect(data).to contain_exactly(
        {
          tag_name: "link",
          url: "/linkauthor/#{user_article.slug}",
          options: "/linkauthor/#{user_article.slug}",
          referenced_type: "Article",
          referenced_id: user_article.id
        },
        {
          tag_name: "post",
          url: "http://#{domain}/currentorg/#{org_article.slug}",
          options: "http://#{domain}/currentorg/#{org_article.slug}",
          referenced_type: "Article",
          referenced_id: org_article.id
        },
        {
          tag_name: "link",
          url: "legacyorg/#{org_article.slug}",
          options: "legacyorg/#{org_article.slug}",
          referenced_type: "Article",
          referenced_id: org_article.id
        },
      )
    end

    it "resolves {% embed %} for organization articles, minimal mode, and subforem domains" do
      org = create(:organization, slug: "embedorg")
      org_article = create(:article, organization: org)
      subforem_article = create(:article)
      allow(Subforem).to receive(:cached_domains).and_return(["sub.example.test"])

      domain = Settings::General.app_domain || "localhost:3000"
      org_url = "https://#{domain}#{org_article.path}"
      subforem_url = "https://sub.example.test#{subforem_article.path}"

      body = <<~MARKDOWN
        {% embed minimal #{org_url} %}
        {% embed #{subforem_url} minimal %}
      MARKDOWN

      holder = create(:article)
      holder.update_column(:body_markdown, body)
      data = described_class.extract(holder)

      expect(data).to contain_exactly(
        {
          tag_name: "embed",
          url: org_url,
          options: "minimal #{org_url}",
          referenced_type: "Article",
          referenced_id: org_article.id
        },
        {
          tag_name: "embed",
          url: subforem_url,
          options: "#{subforem_url} minimal",
          referenced_type: "Article",
          referenced_id: subforem_article.id
        },
      )
    end

    it "resolves {% feed %} references for organizations and tags" do
      org = create(:organization, slug: "feedorg")
      ruby_tag = create(:tag, name: "rubyfeed")
      rails_tag = create(:tag, name: "railsfeed")

      body = <<~MARKDOWN
        {% feed org=feedorg tag=rubyfeed limit=3 %}
        {% feed tags=rubyfeed,railsfeed sort=reactions %}
      MARKDOWN

      holder = create(:article)
      holder.update_column(:body_markdown, body)
      data = described_class.extract(holder)

      expect(data).to contain_exactly(
        {
          tag_name: "feed",
          url: "feedorg",
          options: "org=feedorg tag=rubyfeed limit=3",
          referenced_type: "Organization",
          referenced_id: org.id
        },
        {
          tag_name: "feed",
          url: "rubyfeed",
          options: "tags=rubyfeed,railsfeed sort=reactions",
          referenced_type: "Tag",
          referenced_id: ruby_tag.id
        },
        {
          tag_name: "feed",
          url: "railsfeed",
          options: "tags=rubyfeed,railsfeed sort=reactions",
          referenced_type: "Tag",
          referenced_id: rails_tag.id
        },
      )
    end

    it "resolves {% org %} and {% devcomment %} aliases" do
      org = create(:organization, slug: "aliasorg")
      target_comment = create(:comment)

      holder = create(:article)
      holder.update_column(:body_markdown, "{% org aliasorg %}\n{% devcomment #{target_comment.id_code} %}")

      expect(described_class.extract(holder)).to contain_exactly(
        {
          tag_name: "org",
          url: "aliasorg",
          options: "aliasorg",
          referenced_type: "Organization",
          referenced_id: org.id
        },
        {
          tag_name: "devcomment",
          url: target_comment.id_code,
          options: target_comment.id_code,
          referenced_type: "Comment",
          referenced_id: target_comment.id
        },
      )
    end

    it "extracts embeds from body and minimized markdown on forem_markdown Billboards and skips raw mode" do
      article1 = create(:article)
      article2 = create(:article)
      org = create(:organization, slug: "bbfeedorg")

      billboard = build(
        :billboard,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{article1.path} %}\n{% feed org=bbfeedorg %}",
        minimized_body_markdown: "{% link #{article2.path} %}",
      )

      expect(described_class.extract(billboard)).to contain_exactly(
        {
          tag_name: "link",
          url: article1.path,
          options: article1.path,
          referenced_type: "Article",
          referenced_id: article1.id
        },
        {
          tag_name: "feed",
          url: "bbfeedorg",
          options: "org=bbfeedorg",
          referenced_type: "Organization",
          referenced_id: org.id
        },
        {
          tag_name: "link",
          url: article2.path,
          options: article2.path,
          referenced_type: "Article",
          referenced_id: article2.id
        },
      )

      billboard.render_mode = :raw
      expect(described_class.extract(billboard)).to eq([])
    end
  end
end
