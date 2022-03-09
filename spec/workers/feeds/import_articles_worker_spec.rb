require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, type: :worker, sidekiq: :inline do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "calls the Feeds::Import defaulting to 4 hours ago" do
      allow(Feeds::Import).to receive(:call)
      alice = create(:user)
      bob = create(:user)

      Timecop.freeze(Time.current) do
        worker.perform

        # Each user is run separately. Note that this will not be run
        # sequentially like this in production. This only works like this due
        # to the `sidekiq: :inline` tag on the `RSpec.describe` block
        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [alice.id]), earlier_than: 4.hours.ago.iso8601)
        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [bob.id]), earlier_than: 4.hours.ago.iso8601)
      end
    end

    it "calls the Feeds::Import with the given time" do
      allow(Feeds::Import).to receive(:call)
      alice = create(:user)
      bob = create(:user)

      Timecop.freeze(Time.current) do
        worker.perform([], 1.minute.ago)

        # Each user is run separately
        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [alice.id]), earlier_than: 1.minute.ago.iso8601)
        expect(Feeds::Import)
          .to have_received(:call)
          .with(users_scope: User.where(id: [bob.id]), earlier_than: 1.minute.ago.iso8601)
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
