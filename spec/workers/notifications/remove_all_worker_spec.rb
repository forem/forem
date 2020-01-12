require "rails_helper"
RSpec.describe Notifications::RemoveAllWorker, type: :worker do
  describe "#perform" do
    let(:service) { Notifications::RemoveAll }
    let(:worker) { subject }
    let(:notifiable_type) { "Article" }
    let(:notifiable_id) { 1 }

    before do
      allow(service).to receive(:call)
    end

    it "calls a service" do
      worker.perform(notifiable_id, notifiable_type)
      expect(service).to have_received(:call).with([notifiable_id], notifiable_type).once
    end

    it "does nothing for non-existent notifiable_id" do
      worker.perform(nil, notifiable_type)
      expect(service).not_to have_received(:call)
    end

    it "does nothing for when called for non-notifiable type" do
      worker.perform(notifiable_id, "Other")
      expect(service).not_to have_received(:call)
    end
  end
end
