require "rails_helper"

RSpec.describe ReleasePhaseNotifier, type: :lib do
  describe ".ping_slack" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return("url")
      allow(ApplicationConfig).to receive(:[]).with("SLACK_DEPLOY_CHANNEL").and_return("channel")
    end

    it "sends a failure message to slack" do
      mock_slack = Slack::Notifier.new("url")
      ENV["FAILED_COMMAND"] = "rake db:migrate"
      failure_message = "Release Phase Failed: #{ENV['FAILED_COMMAND']}"
      allow(Slack::Notifier).to receive(:new) { mock_slack }
      allow(mock_slack).to receive(:ping)

      described_class.ping_slack
      expect(mock_slack).to have_received(:ping).with(failure_message)
    end

    it "bails when config variables are missing" do
      allow(ApplicationConfig).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return("")
      allow(ApplicationConfig).to receive(:[]).with("SLACK_DEPLOY_CHANNEL").and_return("")

      expect { described_class.ping_slack }.not_to raise_error
    end

    it "rescues any Slack API Errors" do
      allow(Slack::Notifier).to receive(:new).and_raise(Slack::Notifier::APIError.new)

      expect { described_class.ping_slack }.not_to raise_error
    end
  end
end
