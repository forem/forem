require "rails_helper"

RSpec.describe ExportContentWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", [9999]

  describe "#perform_now" do
    let(:exporter_service) { instance_double(Exporter::Service) }
    let(:user) { create(:user) }

    before do
      allow(Exporter::Service).to receive(:new).and_return(exporter_service)
      allow(exporter_service).to receive(:export)
    end

    it "calls the service" do
      worker.perform(user.id)
      expect(exporter_service).to have_received(:export).once
    end

    it "doesn't call the service if non existent user ID is given" do
      worker.perform(9999)
      expect(exporter_service).not_to have_received(:export)
    end
  end
end
