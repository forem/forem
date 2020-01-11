require "rails_helper"

RSpec.describe Notifications::RemoveAllWorker, type: :woker do
  describe "#perform" do
    let(:worker) { subject }
    let(:remove_all_service) { double }

    before do
      allow(remove_all_service).to receive(:call)
    end

    it "calls the service" do
      worker.perform(1, "Article", remove_all_service)
      expect(remove_all_service).to have_received(:call).with([1], "Article")
    end
  end
end
