require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20261119120000_rerender_comment_embeds.rb")

RSpec.describe DataUpdateScripts::RerenderCommentEmbeds do
  describe "#run" do
    it "starts a single rerender chain at the first record type" do
      allow(RerenderCommentEmbedsWorker).to receive(:perform_async)

      described_class.new.run

      expect(RerenderCommentEmbedsWorker).to have_received(:perform_async).once.with("Comment", 0)
    end

    it "adds the permalink to a previously saved published article that has no embed reference row" do
      comment = create(:comment)
      permalink = %(href="#{URL.comment(comment)}")
      body_markdown = "---\ntitle: Embeds\npublished: true\n---\n\n{% comment #{comment.id_code} %}"
      article = create(:article, body_markdown: body_markdown)
      LiquidEmbedReference.where(record: article).delete_all
      article.update_column(:processed_html, article.processed_html.gsub(permalink, ""))

      Sidekiq::Testing.inline! { described_class.new.run }

      expect(article.reload.processed_html).to include(permalink)
    end
  end
end
