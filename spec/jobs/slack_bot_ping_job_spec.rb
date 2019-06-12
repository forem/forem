require "rails_helper"

RSpec.describe SlackBotPingJob, type: :job do
  describe "#perform_now" do
    before do
      allow(SlackBot).to receive(:ping)
    end

    it "calls the SlackBot" do
      described_class.perform_now(message: "hello",
                                  channel: "#help",
                                  username: "sloan_watch_bot",
                                  icon_emoji: ":sloan:")
      expect(SlackBot).to have_received(:ping).with("hello", channel: "#help",
                                                             username: "sloan_watch_bot",
                                                             icon_emoji: ":sloan:")
    end
  end
end
