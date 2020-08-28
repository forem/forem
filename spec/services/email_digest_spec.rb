require "rails_helper"

RSpec.describe EmailDigest, type: :labor do
  describe "::send_digest_email" do
    it "enqueues Email::SendUserDigestWorker" do
      user = create(:user, email_digest_periodic: true)
      allow(Email::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Email::SendUserDigestWorker).to have_received(:perform_async).with(user.id)
    end
  end
end
