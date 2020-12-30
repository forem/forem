require "rails_helper"

RSpec.describe Articles::RssReaderWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "instructs RssReader to fetch all articles" do
      allow(RssReader).to receive(:get_all_articles)

      worker.perform

      expect(RssReader).to have_received(:get_all_articles).with(force: false)
    end

    it "does not enqueue Feeds::ImportArticlesWorker if the :feeds_import flag is not enabled" do
      allow(RssReader).to receive(:get_all_articles)

      sidekiq_assert_no_enqueued_jobs do
        worker.perform
      end

      expect(RssReader).to have_received(:get_all_articles).with(force: false)
    end

    it "enqueues Feeds::ImportArticlesWorker if the :feeds_import flag is enabled" do
      allow(RssReader).to receive(:get_all_articles)
      allow(FeatureFlag).to receive(:enabled?).with(:feeds_import).and_return(true)

      sidekiq_assert_enqueued_jobs(1, only: Feeds::ImportArticlesWorker) do
        worker.perform
      end

      expect(RssReader).not_to have_received(:get_all_articles)
    end

    it "short circuits if it's running on DEV" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV Community")
      allow(RssReader).to receive(:get_all_articles)
      allow(FeatureFlag).to receive(:enabled?)

      worker.perform

      expect(RssReader).not_to have_received(:get_all_articles)
      expect(FeatureFlag).not_to have_received(:enabled?)
    end
  end
end
