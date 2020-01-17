require "rails_helper"

RSpec.describe Notifications::NewFollowerWorker, type: :worker do
  let(:follow_data) { { followable_type: "User", followable_id: 1, follower_id: 2 } }
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", [{}, true]

  describe "#perform" do
    let(:new_follower_service) { Notifications::NewFollower::Send }

    before { allow(new_follower_service).to receive(:call) }

    it "calls the service" do
      worker.perform(follow_data)
      allow(new_follower_service).to receive(:call).with(follow_data, false).once
    end
  end
end
