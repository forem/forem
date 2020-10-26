require "rails_helper"

RSpec.describe Notifications::RemoveOldNotificationsWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }

    it "fast destroys notifications" do
      allow(Notification).to receive(:fast_destroy_old_notifications)
      worker.perform
      expect(Notification).to have_received(:fast_destroy_old_notifications)
    end
  end
end
