require "rails_helper"

RSpec.describe Notifications::RemoveAllJob, type: :job do
  include_examples "#enqueues_job", "remove_all_notifications", {}

  describe "#perform_now" do
    let(:remove_all_service) { double }

    before do
      allow(remove_all_service).to receive(:call)
    end

    context "when array is empty" do
      it "does not call the service" do
        described_class.perform_now([], remove_all_service)
        expect(remove_all_service).not_to have_received(:call)
      end
    end

    it "calls the service" do
      described_class.perform_now([935, 936], remove_all_service)
      expect(remove_all_service).to have_received(:call).with([935, 936])
    end
  end
end
