require "rails_helper"

RSpec.describe Organizations::ReverifyAllWorker, type: :worker do
  describe "#perform" do
    let!(:organization) do
      org = create(:organization)
      org.update_columns(verified: true, verified_at: Time.current, verification_url: "https://example.com/about")
      org
    end

    it "enqueues a ReverifyOneWorker for each eligible organization" do
      allow(Organizations::ReverifyOneWorker).to receive(:perform_async)

      subject.perform
      expect(Organizations::ReverifyOneWorker).to have_received(:perform_async).with(organization.id)
    end

    it "skips organizations without verification_url" do
      org = create(:organization)
      org.update_columns(verified: true, verification_url: nil)

      allow(Organizations::ReverifyOneWorker).to receive(:perform_async)

      subject.perform
      # Only the first org (with verification_url) should be enqueued
      expect(Organizations::ReverifyOneWorker).to have_received(:perform_async).once
    end

    it "skips admin-verified organizations" do
      organization.update_columns(verification_status: Organization::VERIFICATION_STATUS_ADMIN)

      allow(Organizations::ReverifyOneWorker).to receive(:perform_async)

      subject.perform
      expect(Organizations::ReverifyOneWorker).not_to have_received(:perform_async)
    end
  end
end
