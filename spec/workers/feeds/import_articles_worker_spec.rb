require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, sidekiq: :inline, type: :worker do
  let(:worker) { subject }
  let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "processes jobs for users with feeds" do
      allow(Feeds::Import).to receive(:call)
      alice = create(:user)
      bob = create(:user)
      bob.setting.update_columns(feed_url: feed_url)

      # bob has a feed, and alice doesn't, so we only enqueued for bob

      Timecop.freeze(Time.current) do
        worker.perform

        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [bob.id]), earlier_than: 4.hours.ago.iso8601)
        expect(Feeds::Import)
          .not_to have_received(:call)
          .with(users_scope: User.where(id: [alice.id]), earlier_than: 4.hours.ago.iso8601)
      end
    end

    it "enqueues job for user with the given time" do
      allow(Feeds::Import).to receive(:call)
      user = create(:user)
      user.setting.update_columns(feed_url: feed_url)

      earlier_than = 1.minute.ago
      worker.perform([], earlier_than)

      expect(Feeds::Import).to have_received(:call).with(
        users_scope: User.where(id: user.id),
        earlier_than: earlier_than.iso8601,
      )
    end

    it "calls Feeds::Import with the users from the given user ids and no time" do
      user = create(:user)

      allow(Feeds::Import).to receive(:call)

      worker.perform([user.id])

      expect(Feeds::Import).to have_received(:call).with(users_scope: User.where(id: [user.id]), earlier_than: nil)
    end
  end
end
