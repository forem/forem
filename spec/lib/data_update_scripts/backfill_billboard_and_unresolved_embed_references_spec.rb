require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20261111120000_backfill_billboard_and_unresolved_embed_references.rb",
)

RSpec.describe DataUpdateScripts::BackfillBillboardAndUnresolvedEmbedReferences do
  describe "#run" do
    it "syncs and refreshes active forem_markdown Billboards and bulk-enqueues unresolved embed references" do
      article = create(:article, title: "Backfill Original")
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{article.path} %}",
      )
      LiquidEmbedReference.where(record: billboard).delete_all
      article.update_column(:title, "Backfill Refreshed")

      holder_article = create(:article)
      holder_article.update_column(:body_markdown, "{% link #{article.path} %}")
      unresolved_ref = LiquidEmbedReference.create!(
        record: holder_article,
        tag_name: "link",
        url: article.path,
        options: article.path,
        referenced_type: nil,
        referenced_id: nil,
      )

      allow(SyncLiquidEmbedReferencesWorker).to receive(:perform_bulk)

      described_class.new.run

      expect(billboard.liquid_embed_references.reload.count).to eq(1)
      expect(billboard.liquid_embed_references.first.referenced).to eq(article)
      expect(billboard.reload.processed_html).to include("Backfill Refreshed")
      expect(SyncLiquidEmbedReferencesWorker).to have_received(:perform_bulk)
        .with(include(["Article", unresolved_ref.record_id]))
    end
  end
end
