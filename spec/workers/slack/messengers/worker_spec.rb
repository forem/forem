require "rails_helper"

RSpec.describe Slack::Messengers::Worker, type: :worker do
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
    xit "sends a message to Slack" do
      allow(Slack::Announcer).to receive(:call)

      worker.perform(params)

      expect(Slack::Announcer).to have_received(:call).with(params)
    end

    xit "does nothing if there is missing data" do
      allow(SlackClient).to receive(:ping)

      worker.perform(
        message: nil,
        channel: nil,
        username: nil,
        icon_emoji: nil,
      )

      expect(SlackClient).not_to have_received(:ping)
    end

    xit "works with keys as Strings" do
      allow(Slack::Announcer).to receive(:call)

      worker.perform(params.stringify_keys)

      expect(Slack::Announcer).to have_received(:call).with(params)
    end
  end
end
