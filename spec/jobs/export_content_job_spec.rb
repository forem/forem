require "rails_helper"

RSpec.describe ExportContentJob, type: :job do
  include_examples "#enqueues_job", "export_content", 1

  describe "#perform_now" do
    let(:exporter_service) { double }
    let(:exporter) { double }
    let(:user) { create(:user) }

    before do
      allow(exporter).to receive(:export)
      allow(exporter_service).to receive(:new).and_return(exporter)
    end

    it "calls the service" do
      described_class.perform_now(user.id, exporter_service)
      expect(exporter).to have_received(:export).once
    end

    it "doesn't call the service if non existent user ID is given" do
      described_class.perform_now(9999, exporter_service)
      expect(exporter).not_to have_received(:export)
    end
  end
end
