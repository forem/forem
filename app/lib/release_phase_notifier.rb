class ReleasePhaseNotifier
  def self.ping_slack
    return unless ApplicationConfig["SLACK_WEBHOOK_URL"].present? && ApplicationConfig["SLACK_DEPLOY_CHANNEL"].present?

    client = Slack::Notifier.new(
      ApplicationConfig["SLACK_WEBHOOK_URL"],
      channel: ApplicationConfig["SLACK_DEPLOY_CHANNEL"],
      username: "Heroku",
    )

    client.ping("Release Phase Failed: #{ENV.fetch('FAILED_COMMAND', nil)}")
  rescue Slack::Notifier::APIError => e
    Rails.error.report(e)
  end
end
