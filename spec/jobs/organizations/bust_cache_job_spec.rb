require "rails_helper"

RSpec.describe Organizations::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "organizations_bust_cache", 789, "SlUg"

  describe "#perform_now" do
    let!(:organization) { FactoryBot.create(:organization) }
    let(:cache_buster) { instance_double(CacheBuster) }

    before do
      allow(CacheBuster).to receive(:new).and_return(cache_buster)
      allow(cache_buster).to receive(:bust_organization)
    end

    describe "when no organization is found" do
      it "doest not call the service" do
        allow(Organization).to receive(:find_by).and_return(nil)
        described_class.perform_now(789, "SlUg", cache_buster)
        expect(cache_buster).not_to have_received(:bust_organization)
      end
    end

    it "busts cache" do
      described_class.perform_now(organization.id, "SlUg", cache_buster)
      expect(cache_buster).to have_received(:bust_organization).with(organization, "SlUg")
    end
  end
end
