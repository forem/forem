require "rails_helper"

RSpec.describe RateLimitCheckerJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:service) { PingAdmins }
    let(:job) { subject }

    before { allow(service).to receive(:call) }

    it "calls a service" do
      job.perform(user.id, "test")

      expect(service).to have_received(:call).with(user, "test").once
    end

    it "does nothing for non-existent user" do
      job.perform(nil, "test")

      expect(service).not_to have_received(:call)
    end
  end
end
