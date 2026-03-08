require "rails_helper"

RSpec.describe Notifications::OrganizationDeverificationWorker, type: :worker do
  describe "#perform" do
    let(:organization) { create(:organization) }
    let(:service) { Notifications::OrganizationDeverification::Send }
    let(:worker) { subject }

    before do
      allow(service).to receive(:call)
    end

    it "calls the service" do
      worker.perform(organization.id)
      expect(service).to have_received(:call).with(organization).once
    end

    it "does nothing for non-existent organization" do
      worker.perform(-1)
      expect(service).not_to have_received(:call)
    end
  end
end
