require "rails_helper"

RSpec.describe Notifications::RemoveBySpammerWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:worker) { subject }
    let(:user) { create(:user) }

    before do
      allow(Notifications::RemoveBySpammer).to receive(:call)
    end

    it "calls the service" do
      worker.perform(user.id)
      expect(Notifications::RemoveBySpammer).to have_received(:call).with(user)
    end

    it "doesn't call the service with a non-existent user" do
      worker.perform(-10)
      expect(Notifications::RemoveBySpammer).not_to have_received(:call)
    end
  end
end
