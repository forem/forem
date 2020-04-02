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

    it "does nothing if there is missing data" do
      worker.perform(
        message: nil,
        channel: nil,
        username: nil,
        icon_emoji: nil,
      )

      expect(SlackBot).not_to have_received(:ping)
    end

    it "works with keys as Strings" do
      worker.perform(
        "message" => "hello",
        "channel" => "#help",
        "username" => "sloan_watch_bot",
        "icon_emoji" => ":sloan:",
      )

      expect(SlackBot).to have_received(:ping).with("hello", # message
                                                    channel: "#help",
                                                    username: "sloan_watch_bot",
                                                    icon_emoji: ":sloan:")
    end
  end
end
