require "rails_helper"

RSpec.describe Organizations::BustCacheWorker, type: :worker do
  describe "#perform" do
    let!(:organization) { FactoryBot.create(:organization) }
    let(:worker) { subject }

    before do
      allow(CacheBuster).to receive(:bust_organization)
    end

    describe "when no organization is found" do
      it "doest not call the service" do
        allow(Organization).to receive(:find_by).and_return(nil)
        worker.perform(789, "SlUg")
        expect(CacheBuster).not_to have_received(:bust_organization)
      end
    end

    it "busts cache" do
      worker.perform(organization.id, "SlUg")
      expect(CacheBuster).to have_received(:bust_organization).with(organization, "SlUg")
    end
  end
end
