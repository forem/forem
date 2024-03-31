require "rails_helper"

RSpec.describe Slack::WorkflowWebhookWorker, type: :worker do
  let(:worker) { described_class.new }

  let(:param) { "Hello World" }

  include_examples "#enqueues_on_correct_queue", "low_priority", [
    { "message" => "Hello World" },
  ]

  describe "#perform_now" do
    it "sends a message to Slack" do
      allow(Slack::WorkflowWebhook).to receive(:call)

      worker.perform(param)

      expect(Slack::WorkflowWebhook).to have_received(:call).with(param)
    end
  end
end
