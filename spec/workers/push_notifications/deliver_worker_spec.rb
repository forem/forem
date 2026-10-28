require "rails_helper"

RSpec.describe PushNotifications::DeliverWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    before { allow(Rpush).to receive(:push) }

    it "delivers pending push notifications" do
      worker.perform

      expect(Rpush).to have_received(:push).once
    end

    # Rpush 9 removed the legacy APNs binary protocol along with
    # Rpush.apns_feedback, so calling it raised NoMethodError after every push.
    it "does not raise after delivering" do
      expect { worker.perform }.not_to raise_error
    end
  end
end
