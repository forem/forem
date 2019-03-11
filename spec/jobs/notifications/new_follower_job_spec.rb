require "rails_helper"

RSpec.describe Notifications::NewFollowerJob, type: :job do
  let(:follow_data) { { followable_type: "User", followable_id: 1, follower_id: 2 } }

  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(follow_data, true)
      end.to have_enqueued_job.with(follow_data, true).on_queue("send_new_follower_notification")
    end
  end

  describe "#perform_now" do
    it "calls the service" do
      new_follower_service = double
      allow(new_follower_service).to receive(:call)

      described_class.perform_now(follow_data, false, new_follower_service)
      expect(new_follower_service).to have_received(:call).with(follow_data, false).once
    end
  end
end
