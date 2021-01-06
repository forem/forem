require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "calls the Feeds::Import to get all articles" do
      allow(Feeds::Import).to receive(:call)

      worker.perform(1.hour.ago)

      expect(Feeds::Import).to have_received(:call)
    end

    context "with user ids" do
      it "calls Feeds::Import with the correct users if given user ids" do
        user = create(:user)
        allow(Feeds::Import).to receive(:call)

        worker.perform(nil, [user.id])

        expect(Feeds::Import).to have_received(:call).with(users: User.where(id: [user.id]), earlier_than: nil)
      end
    end

    context "with earlier_than time" do
      it "calls Feeds::Import with the correct time if given" do
        allow(Feeds::Import).to receive(:call)

        Timecop.freeze(Time.current) do
          worker.perform(4.hours.ago)

          expect(Feeds::Import).to have_received(:call).with(users: nil, earlier_than: 4.hours.ago)
        end
      end
    end
  end
end
