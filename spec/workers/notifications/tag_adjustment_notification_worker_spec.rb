require "rails_helper"

RSpec.describe Notifications::TagAdjustmentNotificationWorker, type: :worker do
  let(:worker) { subject }

  # Passing in a random tag_adjustment_id since the worker doesn't actually run
  include_examples "#enqueues_on_correct_queue", "medium_priority", [456]

  describe "#perform" do
    let(:tag_adjustment_service) { Notifications::TagAdjustmentNotification::Send }
    let(:tag_adjustment) { double }

    before { allow(tag_adjustment_service).to receive(:call) }

    describe "When a tag is found" do
      it "calls the service" do
        allow(TagAdjustment).to receive(:find_by).and_return(tag_adjustment)
        allow(tag_adjustment).to receive(:id)

        worker.perform(tag_adjustment.id)

        expect(tag_adjustment_service).to have_received(:call).with(tag_adjustment).once
      end
    end

    describe "When no tag is found" do
      it "does not call the service" do
        allow(TagAdjustment).to receive(:find_by).and_return(nil)

        worker.perform(nil)

        expect(tag_adjustment_service).not_to have_received(:call)
      end
    end
  end
end
