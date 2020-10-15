require "rails_helper"

RSpec.describe Emails::EnqueueDigestWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "sends periodic digest email" do
      allow(EmailDigest).to receive(:send_periodic_digest_email)
      worker.perform
      expect(EmailDigest).to have_received(:send_periodic_digest_email)
    end
  end
end
