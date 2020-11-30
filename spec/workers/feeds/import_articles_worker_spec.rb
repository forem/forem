require "rails_helper"

RSpec.describe Feeds::ImportArticlesWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "calls the Feeds::Import to get all articles" do
      allow(Feeds::Import).to receive(:call)

      worker.perform

      expect(Feeds::Import).to have_received(:call)
    end

    context "with user ids" do
      it "calls Feeds::Import with the correct users if given user ids" do
        user = create(:user)
        allow(Feeds::Import).to receive(:call)

        worker.perform([user.id])

        expect(Feeds::Import).to have_received(:call).with(users: User.where(id: [user.id]))
      end
    end
  end
end
