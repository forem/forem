require "rails_helper"

RSpec.describe Organizations::BustCacheWorker, type: :worker do
  describe "#perform" do
    let!(:organization) { FactoryBot.create(:organization) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::BustOrganization).to receive(:call)
    end

    describe "when no organization is found" do
      it "doest not call the service" do
        allow(Organization).to receive(:find_by).and_return(nil)
        worker.perform(789, "SlUg")
        expect(EdgeCache::BustOrganization).not_to have_received(:call)
      end
    end

    describe "when no slug is found" do
      it "doest not call the service" do
        worker.perform(organization.id, nil)
        expect(EdgeCache::BustOrganization).not_to have_received(:call)
      end
    end

    it "busts cache" do
      worker.perform(organization.id, "SlUg")
      expect(EdgeCache::BustOrganization).to have_received(:call).with(organization, "SlUg")
    end
  end
end
