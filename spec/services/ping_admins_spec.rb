require "rails_helper"

RSpec.describe PingAdmins, type: :service do
  let(:user) { build_stubbed(:user) }

  describe "#call" do
    subject(:ping_admin_call) { described_class.call(user) }

    before { allow(SlackBot).to receive(:ping) }

    context "when user isn't nil" do
      let(:action) { "unknown" }
      let(:message_expected) { "Rate limit exceeded (#{action}). https://dev.to#{user.path}" }

      it "calls SlackBot.ping" do
        ping_admin_call

        expect(SlackBot).to have_received(:ping).with(message_expected,
                                                      channel: "abuse-reports",
                                                      username: "rate_limit",
                                                      icon_emoji: ":hand:")
      end
    end

    context "when user is nil" do
      let(:user) { nil }

      it "doesnt call SlackBot.ping" do
        expect(ping_admin_call).to be_nil
        expect(SlackBot).not_to have_received(:ping)
      end
    end

    context "when receive action" do
      subject(:ping_admin_call) { described_class.call(user, action) }

      let(:action) { "any-action" }
      let(:message_expected) { "Rate limit exceeded (#{action}). https://dev.to#{user.path}" }

      it "calls SlackBot.ping" do
        ping_admin_call

        expect(SlackBot).to have_received(:ping).with(message_expected,
                                                      channel: "abuse-reports",
                                                      username: "rate_limit",
                                                      icon_emoji: ":hand:")
      end
    end
  end
end
