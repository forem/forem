require "rails_helper"

RSpec.describe EmailDigest, type: :labor do
  describe "::send_digest_email" do
    it "enqueues Emails::SendUserDigestWorker" do
      user = create(:user, email_digest_periodic: true)
      allow(Emails::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Emails::SendUserDigestWorker).to have_received(:perform_async).with(user.id)
    end
  end
end
