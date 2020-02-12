require "rails_helper"
RSpec.describe Notifications::WelcomeNotificationWorker, type: :worker do
  describe "#perform" do
    let!(:broadcast) { create(:broadcast, :onboarding) }
    let(:user) { create(:user) }
    let(:service) { Notifications::WelcomeNotification::Send }
    let(:worker) { subject }

    before do
      allow(service).to receive(:call)
    end

    it "calls a service" do
      worker.perform(user.id, broadcast.id)
      expect(service).to have_received(:call).with(user.id, broadcast).once
    end

    context "when there is a non-existent broadcast" do
      before do
        broadcast.destroy
      end

      it "does nothing" do
        worker.perform(user.id, broadcast.id)
        expect(service).not_to have_received(:call)
      end
    end
  end
end
