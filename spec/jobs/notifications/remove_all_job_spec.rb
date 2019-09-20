require "rails_helper"

RSpec.describe Notifications::RemoveAllJob, type: :job do
  include_examples "#enqueues_job", "remove_all_notifications", {}

  describe "#perform_now" do
    let(:remove_all_service) { double }

    before do
      allow(remove_all_service).to receive(:call)
    end

    it "calls the service" do
      described_class.perform_now(1, "Article", remove_all_service)
      expect(remove_all_service).to have_received(:call).with([1], "Article")
    end
  end
end
