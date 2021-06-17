require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "calls the Feeds::Import defaulting to 4 hours ago" do
      allow(Feeds::Import).to receive(:call)

      Timecop.freeze(Time.current) do
        worker.perform

        expect(Feeds::Import).to have_received(:call).with(users: nil, earlier_than: 4.hours.ago)
      end
    end

    it "calls the Feeds::Import with the given time" do
      allow(Feeds::Import).to receive(:call)

      Timecop.freeze(Time.current) do
        worker.perform([], 1.minute.ago)

        expect(Feeds::Import).to have_received(:call).with(users: nil, earlier_than: 1.minute.ago)
      end
    end

    it "calls Feeds::Import with the users from the given user ids and no time" do
      user = create(:user)

      allow(Feeds::Import).to receive(:call)

      worker.perform([user.id])

      expect(Feeds::Import).to have_received(:call).with(users: User.where(id: [user.id]), earlier_than: nil)
    end
  end
end
