require "rails_helper"

RSpec.describe RateLimitCheckerJob, type: :job do
  include_examples "#enqueues_job", "rate_limit_checker", 2

  describe "#perform_later" do
    let(:user) { create(:user) }
    let(:service) { PingAdmins }

    before { allow(service).to receive(:call) }

    it "enqueues the job" do
      expect do
        described_class.perform_later(user.id)
      end.to have_enqueued_job.with(user.id).on_queue("rate_limit_checker")
    end

    it "calls a service" do
      perform_enqueued_jobs do
        described_class.perform_now(user.id)

        expect(service).to have_received(:call).with(user).once
      end
    end

    it "does nothing for non-existent user" do
      perform_enqueued_jobs do
        described_class.perform_now(nil)

        expect(service).not_to have_received(:call)
      end
    end
  end
end
