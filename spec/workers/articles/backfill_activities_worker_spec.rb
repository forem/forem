require "rails_helper"

RSpec.describe Articles::BackfillActivitiesWorker do
  describe "#perform" do
    it "backfills missing rows as one batch" do
      articles = create_list(:article, 2)
      ids = articles.map(&:id)
      allow(ArticleActivity).to receive(:bulk_backfill!)

      described_class.new.perform(ids)

      expect(ArticleActivity).to have_received(:bulk_backfill!).with(ids)
    end

    it "skips existing rows" do
      article = create(:article)
      activity = ArticleActivity.create!(article: article, total_page_views: 12)
      allow(ArticleActivity).to receive(:bulk_backfill!)

      described_class.new.perform([article.id])

      expect(ArticleActivity).not_to have_received(:bulk_backfill!)
      expect(activity.reload.total_page_views).to eq(12)
    end
  end
end
