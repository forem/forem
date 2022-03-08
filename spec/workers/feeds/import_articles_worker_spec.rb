require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, type: :worker, sidekiq: :inline do
  let(:worker) { subject }
  let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "processes jobs for users with feeds", vcr: "feeds_import" do
      allow(Feeds::Import).to receive(:call)
      create(:user) # alice
      bob = create(:user)
      bob.setting.update(feed_url: feed_url)

      # bob has a feed, and alice doesn't, so we only enqueued for bob

      Timecop.freeze(Time.current) do
        worker.perform

        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [bob.id]), earlier_than: 4.hours.ago.iso8601)
      end
    end

    it "enqueues job for user with the given time", vcr: "feeds_import", sidekiq: :fake do
      create(:user) # alice
      bob = create(:user)
      bob.setting.update(feed_url: feed_url)

      Timecop.freeze(Time.current) do
        earlier_than = 1.minute.ago

        sidekiq_assert_enqueued_with(job: Feeds::ImportArticlesWorker::ForUser, args: [bob.id, earlier_than.iso8601]) do
          worker.perform([], earlier_than)
        end
      end
    end

    it "calls Feeds::Import with the users from the given user ids and no time" do
      user = create(:user)

      allow(Feeds::Import).to receive(:call)

      worker.perform([user.id])

      expect(Feeds::Import).to have_received(:call).with(users_scope: User.where(id: [user.id]), earlier_than: nil)
    end
  end
end
