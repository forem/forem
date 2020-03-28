require "rails_helper"
RSpec.describe Notifications::WelcomeNotificationWorker, type: :worker do
  describe "#perform" do
    let(:broadcast) { create(:onboarding_broadcast) }
    let(:inactive_broadcast) { create(:onboarding_broadcast, active: false) }
    let(:user) { create(:user) }
    let(:service) { Notifications::WelcomeNotification::Send }
    let(:worker) { subject }

    before do
      allow(service).to receive(:call)
    end

    context "with an active broadcast" do
      it "calls a service" do
        worker.perform(user.id, broadcast.id)
        expect(service).to have_received(:call).with(user.id, broadcast).once
      end
    end

    context "with an inactive broadcast" do
      it "does not call a service" do
        worker.perform(user.id, inactive_broadcast.id)
        expect(service).not_to have_received(:call)
      end
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
