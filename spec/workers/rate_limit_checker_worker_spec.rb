require "rails_helper"

RSpec.describe RateLimitCheckerWorker, type: :worker do
  describe "#perform_async" do
    it "enqueues a job correctly" do
      sidekiq_assert_enqueued_with(job: described_class, args: [1, "test"], queue: "default") do
        described_class.perform_async(1, "test")
      end
    end
  end

  describe "#perform" do
    let(:user) { create(:user) }
    let(:service) { PingAdmins }
    let(:worker) { subject }

    before { allow(service).to receive(:call) }

    it "calls a service" do
      worker.perform(user.id, "test")

      expect(service).to have_received(:call).with(user, "test").once
    end

    it "does nothing for non-existent user" do
      worker.perform(nil, "test")

      expect(service).not_to have_received(:call)
    end
  end
end
