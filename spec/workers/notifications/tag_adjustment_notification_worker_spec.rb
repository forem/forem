require "rails_helper"
RSpec.describe Notifications::TagAdjustmentNotificationWorker, type: :woker do
  describe "#perform" do
    let(:tag_adjustment) { double }
    let(:service) { Notifications::TagAdjustmentNotification::Send }
    let(:worker) { subject }
    let(:id) { rand(1000) }

    before do
      allow(service).to receive(:call)
    end

    it "calls a service" do
      allow(TagAdjustment).to receive(:find_by).and_return(tag_adjustment)
      worker.perform(id)
      expect(service).to have_received(:call).with(tag_adjustment).once
    end

    it "does nothing for non-existent tag adjustment" do
      worker.perform(nil)
      expect(service).not_to have_received(:call)
    end
  end
end
