require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20261119120000_rerender_comment_embeds.rb")

RSpec.describe DataUpdateScripts::RerenderCommentEmbeds do
  describe "#run" do
    let(:comment) { create(:comment) }
    let(:permalink) { %(href="#{URL.comment(comment)}") }

    def create_published_article_embedding_comment
      article = create(:article, body_markdown: "---\ntitle: Embeds #{rand(1000)}\npublished: true\n---\n\n" \
                                                "{% comment #{comment.id_code} %}")
      SyncLiquidEmbedReferencesWorker.new.perform("Article", article.id)
      article
    end

    it "adds the permalink to a previously saved published article without an author edit" do
      article = create_published_article_embedding_comment
      article.update_column(:processed_html, article.processed_html.gsub(permalink, ""))
      expect(article.reload.processed_html).not_to include(permalink)

      Sidekiq::Testing.inline! { described_class.new.run }

      expect(article.reload.processed_html).to include(permalink)
    end

    it "enqueues one batch per record type for records embedding a comment" do
      article = create_published_article_embedding_comment
      allow(RefreshLiquidEmbedRecordsWorker).to receive(:perform_async)

      described_class.new.run

      expect(RefreshLiquidEmbedRecordsWorker).to have_received(:perform_async).with("Article", [article.id])
    end

    it "ignores records that embed no comment" do
      article = create(:article)
      SyncLiquidEmbedReferencesWorker.new.perform("Article", article.id)
      allow(RefreshLiquidEmbedRecordsWorker).to receive(:perform_async)

      described_class.new.run

      expect(RefreshLiquidEmbedRecordsWorker).not_to have_received(:perform_async)
    end
  end
end
