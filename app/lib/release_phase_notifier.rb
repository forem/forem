class ReleasePhaseNotifier
  def self.ping_slack
    return unless ApplicationConfig["SLACK_WEBHOOK_URL"].present? && ApplicationConfig["SLACK_DEPLOY_CHANNEL"].present?

    client = Slack::Notifier.new(
      ApplicationConfig["SLACK_WEBHOOK_URL"],
      channel: ApplicationConfig["SLACK_DEPLOY_CHANNEL"],
      username: "Heroku",
    )

    client.ping("Release Phase Failed: #{ENV['FAILED_COMMAND']}")
  rescue Slack::Notifier::APIError => e
    Rails.logger.info("Slack API error occured: #{e.message}")
  end
end
