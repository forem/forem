require "rails_helper"

RSpec.describe SyncLiquidEmbedReferencesWorker do
  describe "#perform" do
    let(:comment) { create(:comment, body_markdown: "Initial {% youtube dQw4w9WgXcQ %}") }

    it "synchronizes liquid embed definitions into the database safely" do
      LiquidEmbedReference.delete_all

      expect do
        described_class.new.perform("Comment", comment.id)
      end.to change(LiquidEmbedReference, :count).by(1)

      ref = LiquidEmbedReference.last
      expect(ref.record).to eq(comment)
      expect(ref.tag_name).to eq("youtube")
      expect(ref.url).to eq("dQw4w9WgXcQ")
    end

    it "persists newly populated attributes for publication status, date, and score mapping to the source record" do
      body = <<~MARKDOWN
        ---
        title: Valid Native Test Title
        ---
        {% youtube dQw4w9WgXcQ %}
      MARKDOWN
      article = create(:article, body_markdown: body)
      article.update_columns(score: 42, published: true, published_at: 2.days.ago)

      described_class.new.perform("Article", article.id)

      ref = LiquidEmbedReference.last
      expect(ref.score).to eq(42)
      expect(ref.published).to be(true)
      expect(ref.published_at.to_i).to eq(article.published_at.to_i)
    end

    it "efficiently propagates score and publication changes inline via the concern update_all native hook" do
      body = <<~MARKDOWN
        ---
        title: Valid Native Propagate Title
        ---
        {% youtube abcdefghijk %}
      MARKDOWN
      article = create(:article, body_markdown: body)
      article.update_columns(score: 10, published: false, published_at: 1.day.ago)

      described_class.new.perform("Article", article.id)

      ref = article.liquid_embed_references.first
      expect(ref.score).to eq(10)
      expect(ref.published).to be(false)

      # Trigger the after_commit sync_liquid_embed_metadata mapping simulated update!
      article.update_columns(score: 99, published: true)
      article.__send__(:sync_liquid_embed_metadata)

      ref.reload
      expect(ref.score).to eq(99)
      expect(ref.published).to be(true)
    end

    it "truncates urls that would exceed the btree index row size limit" do
      long_url = "https://example.com/#{SecureRandom.alphanumeric(6000)}"
      comment.update_column(:body_markdown, "{% embed #{long_url} %} {% youtube dQw4w9WgXcQ %}")
      LiquidEmbedReference.delete_all

      expect do
        described_class.new.perform("Comment", comment.id)
      end.to change(LiquidEmbedReference, :count).by(2)

      ref = LiquidEmbedReference.find_by(tag_name: "embed")
      expect(ref.url.bytesize).to eq(described_class::MAX_URL_BYTES)
      expect(long_url).to start_with(ref.url)
      expect(ref.options).to eq(long_url)
    end

    it "flushes and overwrites previous embeds strictly mirroring the latest markdown state" do
      described_class.new.perform("Comment", comment.id)
      expect(LiquidEmbedReference.count).to eq(1)

      comment.update!(body_markdown: "{% twitter 1234567890 %}")

      described_class.new.perform("Comment", comment.id)

      expect(LiquidEmbedReference.count).to eq(1)
      ref = LiquidEmbedReference.last
      expect(ref.tag_name).to eq("twitter")
      expect(ref.url).to eq("1234567890")
    end

    it "synchronizes Billboard embeds with active publication status and busts feed target cache" do
      org = create(:organization, slug: "bbsyncorg")
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% feed org=bbsyncorg %}",
      )
      LiquidEmbedReference.delete_all

      allow(LiquidEmbedReference).to receive(:bust_feed_targets_cache!).and_call_original

      expect do
        described_class.new.perform("Billboard", billboard.id)
      end.to change(LiquidEmbedReference, :count).by(1)

      expect(LiquidEmbedReference).to have_received(:bust_feed_targets_cache!).at_least(:once)
      ref = billboard.liquid_embed_references.last
      expect(ref.tag_name).to eq("feed")
      expect(ref.referenced).to eq(org)
      expect(ref.published).to be(true)
    end

    it "skips DELETE queries when markdown has no embeds and no prior references exist" do
      plain_comment = create(:comment, body_markdown: "Plain markdown without liquid tags")
      LiquidEmbedReference.where(record: plain_comment).delete_all

      delete_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        delete_queries << sql if sql.include?('DELETE FROM "liquid_embed_references"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.new.perform("Comment", plain_comment.id)
      end

      expect(delete_queries).to be_empty
    end

    it "skips enqueuing SyncLiquidEmbedReferencesWorker on plain markdown without liquid tags" do
      allow(described_class).to receive(:perform_async)

      plain_comment = create(:comment, body_markdown: "Just plain text")
      plain_comment.update!(body_markdown: "Still plain text")

      expect(described_class).not_to have_received(:perform_async)
    end
  end
end
