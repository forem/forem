require "rails_helper"

RSpec.describe SlackBotPingWorker, type: :worker do
  let(:worker) { subject }
  let(:params) do
    {
      message: "hello",
      channel: "#help",
      username: "sloan_watch_bot",
      icon_emoji: ":sloan:"
    }
  end

  include_examples "#enqueues_on_correct_queue", "default", [
    { message: "hello", channel: "#help", username: "sloan_watch_bot", icon_emoji: ":sloan:" },
  ]

  describe "#perform_now" do
    before { allow(Slack::Announcer).to receive(:call) }

    it "calls the SlackBot" do
      worker.perform(params)

      expect(Slack::Announcer).to have_received(:call).with(params)
    end

    it "does nothing if there is missing data" do
      worker.perform(
        message: nil,
        channel: nil,
        username: nil,
        icon_emoji: nil,
      )

      expect(Slack::Announcer).not_to have_received(:call)
    end

    it "works with keys as Strings" do
      worker.perform(params.stringify_keys)

      expect(Slack::Announcer).to have_received(:call).with(params)
    end
  end
end
