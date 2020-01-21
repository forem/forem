require "rails_helper"

RSpec.describe SlackBotPingWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "default", [{ message: "hello", channel: "#help", username: "sloan_watch_bot", icon_emoji: ":sloan:" }]

  describe "#perform_now" do
    before { allow(SlackBot).to receive(:ping) }

    it "calls the SlackBot" do
      worker.perform(
        message: "hello",
        channel: "#help",
        username: "sloan_watch_bot",
        icon_emoji: ":sloan:",
      )

      expect(SlackBot).to have_received(:ping).with("hello", # message
                                                    channel: "#help",
                                                    username: "sloan_watch_bot",
                                                    icon_emoji: ":sloan:")
    end
  end
end
