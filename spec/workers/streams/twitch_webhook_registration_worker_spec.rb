require "rails_helper"

RSpec.describe Streams::TwitchWebhookRegistrationWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:user) { create(:user, twitch_username: "test-username") }
    let(:worker) { subject }
    let(:service) { Streams::TwitchWebhook::Register }

    before do
      allow(service).to receive(:call)
    end

    context "when the user does NOT have a twitch username present" do
      let(:user) { create(:user) }

      it "noops" do
        worker.perform(user.id)

        expect(service).not_to have_received(:call)
      end
    end

    it "noops when the id passed does not belong to a user" do
      worker.perform(987_654_321)

      expect(service).not_to have_received(:call)
    end

    it "registers for webhooks" do
      worker.perform(user.id)

      expect(service).to have_received(:call).with(user)
    end
  end
end
