class ReleasePhaseNotifier
  def self.ping_slack
    client = Slack::Notifier.new(
      ApplicationConfig["SLACK_WEBHOOK_URL"],
      channel: ApplicationConfig["SLACK_DEPLOY_CHANNEL"],
      username: "heroku",
    )

    client.ping("Release Phase Failed: #{ENV['FAILED_COMMAND']}")
  end
end
