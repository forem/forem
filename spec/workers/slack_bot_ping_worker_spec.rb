require "rails_helper"

RSpec.describe SlackBotPingWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "default", ["hello", "#help", "sloan_watch_bot", ":sloan:"]

  describe "#perform_now" do
    before { allow(SlackBot).to receive(:ping) }

    it "calls the SlackBot" do
      worker.perform(
        "hello", # message
        "#help", # channel
        "sloan_watch_bot", # username
        ":sloan:", # icon_emoji
      )

      expect(SlackBot).to have_received(:ping).with("hello", # message
                                                    channel: "#help",
                                                    username: "sloan_watch_bot",
                                                    icon_emoji: ":sloan:")
    end
  end
end
