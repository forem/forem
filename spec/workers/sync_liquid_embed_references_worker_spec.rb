require "rails_helper"

RSpec.describe SyncLiquidEmbedReferencesWorker do
  describe "#perform" do
    let(:comment) { create(:comment, body_markdown: "Initial {% youtube dQw4w9WgXcQ %}") }

    it "synchronizes liquid embed definitions into the database safely" do
      LiquidEmbedReference.delete_all

      expect {
        described_class.new.perform("Comment", comment.id)
      }.to change(LiquidEmbedReference, :count).by(1)

      ref = LiquidEmbedReference.last
      expect(ref.record).to eq(comment)
      expect(ref.tag_name).to eq("youtube")
      expect(ref.url).to eq("dQw4w9WgXcQ")
    end

    it "persists newly populated attributes for publication status, date, and score mapping natively to the source record" do
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
      article.send(:sync_liquid_embed_metadata)

      ref.reload
      expect(ref.score).to eq(99)
      expect(ref.published).to be(true)
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
  end
end
