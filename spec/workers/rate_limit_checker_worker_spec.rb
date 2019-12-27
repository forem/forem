require "rails_helper"

RSpec.describe RateLimitCheckerWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:service) { PingAdmins }
    let(:worker) { subject }

    before { allow(service).to receive(:call) }

    it "calls a service" do
      perform_enqueued_jobs do
        worker.perform(user.id, "test")

        expect(service).to have_received(:call).with(user, "test").once
      end
    end

    it "does nothing for non-existent user" do
      perform_enqueued_jobs do
        worker.perform(nil, "test")

        expect(service).not_to have_received(:call)
      end
    end
  end
end
