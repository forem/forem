require "rails_helper"

RSpec.describe ReleasePhaseNotifier, type: :lib do
  describe ".ping_slack" do
    it "sends a failure message to slack" do
      mock_slack = Slack::Notifier.new("url")
      ENV["FAILED_COMMAND"] = "rake db:migrate"
      failure_message = "Release Phase Failed: #{ENV['FAILED_COMMAND']}"
      allow(Slack::Notifier).to receive(:new) { mock_slack }
      allow(mock_slack).to receive(:ping)

      described_class.ping_slack
      expect(mock_slack).to have_received(:ping).with(failure_message)
    end
  end
end
