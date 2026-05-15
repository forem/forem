require "rails_helper"

RSpec.describe PageView do
  let(:page_view) { create(:page_view, referrer: "http://example.com/page") }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:article).optional }

  context "when callbacks are triggered before create" do
    describe "#domain" do
      it "is automatically set when a new page view is created" do
        expect(page_view.domain).to eq("example.com")
      end
    end

    describe "#path" do
      it "is automatically set when a new page view is created" do
        expect(page_view.path).to eq("/page")
      end
    end
  end

  describe "#enqueue_article_activity_update callback" do
    let(:article) { create(:article) }

    it "enqueues UpdateArticleActivityWorker for article page views" do
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      create(:page_view, article: article)
      expect(Articles::UpdateArticleActivityWorker)
        .to have_received(:perform_async)
        .with(article.id, "page_view", "create", hash_including("iso", "domain"))
    end

    it "does not enqueue when article_id is nil (non-article page view)" do
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      PageView.create!(article_id: nil, counts_for_number_of_views: 1, time_tracked_in_seconds: 0)
      expect(Articles::UpdateArticleActivityWorker).not_to have_received(:perform_async)
    end
  end

end
