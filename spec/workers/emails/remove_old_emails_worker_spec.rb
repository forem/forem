require "rails_helper"

RSpec.describe Emails::RemoveOldEmailsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }

    it "fast destroys notifications" do
      allow(EmailMessage).to receive(:fast_destroy_old_retained_email_deliveries)
      worker.perform
      expect(EmailMessage).to have_received(:fast_destroy_old_retained_email_deliveries)
    end
  end
end
