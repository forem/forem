require "rails_helper"

RSpec.describe Articles::DevRssReaderWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "does not call the RssReader for non DEV communities" do
      allow(SiteConfig).to receive(:community_name).and_return("NotDEV")
      allow(RssReader).to receive(:get_all_articles)

      worker.perform

      expect(RssReader).not_to have_received(:get_all_articles)
    end

    it "does not call the RssReader if the cache instructs it to cancel" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV")
      allow(Rails.cache).to receive(:read).with("cancel_rss_job").and_return("true")

      allow(RssReader).to receive(:get_all_articles)

      worker.perform

      expect(RssReader).not_to have_received(:get_all_articles)
    end

    it "calls the RssReader to get all articles" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV")
      allow(Rails.cache).to receive(:read).with("cancel_rss_job").and_return(nil)
      allow(RssReader).to receive(:get_all_articles)

      worker.perform

      expect(RssReader).to have_received(:get_all_articles).with(force: true)
    end
  end
end
