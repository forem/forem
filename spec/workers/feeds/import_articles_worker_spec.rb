require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, sidekiq: :inline, type: :worker do
  let(:worker) { subject }
  let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    before do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
    end

    it "processes jobs for active feeds" do
      allow(Feeds::Import).to receive(:call)
      user = create(:user)
      feed = RssFeed.create!(user: user, url: feed_url)
      
      # feed is active, so we enqueue for it
      Timecop.freeze(Time.current) do
        worker.perform

        expect(Feeds::Import)
          .to have_received(:call)
          .with(feeds_scope: RssFeed.where(id: [feed.id]), earlier_than: 4.hours.ago.iso8601)
      end
    end

    it "enqueues job for feed with the given time" do
      allow(Feeds::Import).to receive(:call)
      user = create(:user)
      feed = RssFeed.create!(user: user, url: feed_url)

      earlier_than = 1.minute.ago
      worker.perform([], earlier_than)

      expect(Feeds::Import).to have_received(:call).with(
        feeds_scope: RssFeed.where(id: [feed.id]),
        earlier_than: earlier_than.iso8601,
      )
    end

    it "calls Feeds::Import with the feeds from the given feed ids and no time" do
      user = create(:user)
      feed = RssFeed.create!(user: user, url: feed_url)

      allow(Feeds::Import).to receive(:call)

      worker.perform([feed.id])

      expect(Feeds::Import).to have_received(:call).with(feeds_scope: RssFeed.where(id: [feed.id]), earlier_than: nil)
    end
  end
end
