require "rails_helper"

RSpec.describe Streams::TwitchWebhookRegistrationWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "default", 1

  describe "#perform" do
    let(:user) { create(:user, twitch_username: "test-username") }
    let(:worker) { subject }
    let(:service) { double }

    before do
      allow(service).to receive(:call)
    end

    context "when the user does NOT have a twitch username present" do
      let(:user) { create(:user) }

      it "noops" do
        worker.perform(user.id, service)

        expect(service).not_to have_received(:call)
      end
    end

    it "noops when the id passed does not belong to a user" do
      worker.perform(987_654_321, service)

      expect(service).not_to have_received(:call)
    end

    it "registers for webhooks" do
      worker.perform(user.id, service)

      expect(service).to have_received(:call).with(user)
    end
  end
end
