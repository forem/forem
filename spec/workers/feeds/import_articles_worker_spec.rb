require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, sidekiq: :inline, type: :worker do
  let(:worker) { subject }
  let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "processes jobs for users with active feeds" do
      allow(Feeds::Import).to receive(:call)
      create(:user, last_article_at: 1.week.ago)
      bob = create(:user, last_article_at: 1.week.ago)
      bob_feed = create(:rss_feed, user: bob, feed_url: feed_url, status: :active)

      # bob has a feed, and alice doesn't, so we only enqueued for bob

      Timecop.freeze(Time.current) do
        worker.perform

        expect(Feeds::Import)
          .to have_received(:call)
          .with(rss_feeds_scope: RssFeed.fetchable.where(id: [bob_feed.id]), earlier_than: 4.hours.ago.iso8601)
      end
    end

    it "enqueues job with the given time" do
      allow(Feeds::Import).to receive(:call)
      user = create(:user, last_article_at: 1.week.ago)
      feed = create(:rss_feed, user: user, feed_url: feed_url, status: :active)

      earlier_than = 1.minute.ago
      worker.perform([], earlier_than)

      expect(Feeds::Import).to have_received(:call).with(
        rss_feeds_scope: RssFeed.fetchable.where(id: feed.id),
        earlier_than: earlier_than.iso8601,
      )
    end

    it "calls Feeds::Import with feeds for the given user ids and no time" do
      user = create(:user)
      feed = create(:rss_feed, user: user, feed_url: feed_url, status: :active)

      allow(Feeds::Import).to receive(:call)

      worker.perform([user.id])

      expect(Feeds::Import).to have_received(:call).with(
        rss_feeds_scope: RssFeed.fetchable.where(id: [feed.id]),
        earlier_than: nil,
      )
    end
  end

  describe Feeds::ImportArticlesWorker::ForFeed do
    it "calls Feeds::Import with the given feed ids" do
      user = create(:user)
      feed = create(:rss_feed, user: user, feed_url: feed_url, status: :active)

      allow(Feeds::Import).to receive(:call)

      described_class.new.perform([feed.id], nil)

      expect(Feeds::Import).to have_received(:call).with(
        rss_feeds_scope: RssFeed.fetchable.where(id: [feed.id]),
        earlier_than: nil,
      )
    end
  end

  describe Feeds::ImportArticlesWorker::ForUser do
    it "calls Feeds::Import with feeds for the given user ids (backward compat)" do
      user = create(:user)
      create(:rss_feed, user: user, feed_url: feed_url, status: :active)

      allow(Feeds::Import).to receive(:call)

      described_class.new.perform([user.id], nil)

      expect(Feeds::Import).to have_received(:call).with(
        rss_feeds_scope: RssFeed.fetchable.where(user_id: [user.id]),
        earlier_than: nil,
      )
    end
  end
end
