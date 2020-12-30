require "rails_helper"

RSpec.describe EmailDigest, type: :service do
  describe "::send_digest_email" do
    it "enqueues Emails::SendUserDigestWorker" do
      user = create(:user, email_digest_periodic: true)
      allow(Emails::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Emails::SendUserDigestWorker).to have_received(:perform_async).with(user.id)
    end

    it "performs job inline if community is DEV" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV Community")
      user = create(:user, email_digest_periodic: true)
      worker = Emails::SendUserDigestWorker.new
      allow(worker).to receive(:perform)
      allow(Emails::SendUserDigestWorker).to receive(:new).and_return(worker)
      allow(Emails::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async)
      expect(worker).to have_received(:perform).with(user.id)
    end
  end
end
