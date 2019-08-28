require "rails_helper"

RSpec.describe Notifications::RemoveEachJob, type: :job do
  include_examples "#enqueues_job", "remove_each_notifications", []

  describe "#perform_now" do
    let(:remove_each_service) { double }

    before do
      allow(remove_each_service).to receive(:call)
    end

    context "when array is empty" do
      it "does not call the service" do
        described_class.perform_now([], remove_each_service)
        expect(remove_each_service).not_to have_received(:call)
      end
    end

    it "calls the service" do
      described_class.perform_now([935, 936], remove_each_service)
      expect(remove_each_service).to have_received(:call).with([935, 936])
    end
  end
end
