require "rails_helper"

RSpec.describe RateLimitCheckerWorker, type: :worker do
  it { is_expected.to be_processed_in :default }
  it { is_expected.to be_retryable 10 }

  describe "#perform" do
    let_it_be(:service) { PingAdmins }
    let(:worker) { subject }

    before { allow(service).to receive(:call) }

    context "with user" do
      let_it_be(:user) { create(:user) }

      it "calls a service" do
        worker.perform(user.id, "test")

        expect(service).to have_received(:call).with(user, "test").once
      end
    end

    context "without user" do
      it "does nothing for non-existent user" do
        expect { worker.perform(nil, "test") }.not_to raise_error

        expect(service).not_to have_received(:call)
      end
    end
  end
end
