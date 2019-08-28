require "rails_helper"

RSpec.describe Notifications::TagAdjustmentNotificationJob do
  include_examples "#enqueues_job", "send_tag_adjustment_notification", 333

  describe "#perform_now" do
    let(:id) { rand(1000) }
    let(:tag_adjustment_service) { double }
    let(:tag_adjustment) { double }

    before do
      allow(tag_adjustment_service).to receive(:call)
    end

    describe "When a tag is found" do
      it "calls the service" do
        allow(TagAdjustment).to receive(:find_by).and_return(tag_adjustment)
        perform
        expect(tag_adjustment_service).to have_received(:call)
      end
    end

    describe "When no tag is found" do
      it "does not call the service" do
        allow(TagAdjustment).to receive(:find_by).and_return(nil)
        perform
        expect(tag_adjustment_service).not_to have_received(:call)
      end
    end

    def perform
      described_class.perform_now(id, tag_adjustment_service)
    end
  end
end
