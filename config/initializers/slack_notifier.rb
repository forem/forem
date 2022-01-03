Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join("lib/slack/notifier/util/*.rb")).each do |filename|
    require_dependency filename
  end
end

class NoOpHTTPClient
  def self.post(uri, kwargs = {})
    # bonus, you could log or observe posted params here
  end
end

module SlackNotifierInitializer
  def self.create_test_channel_notifier
    return create_stubbed_notifier if ApplicationConfig["SLACK_WEBHOOK_URL"].blank?

    Slack::Notifier.new(
      ApplicationConfig["SLACK_WEBHOOK_URL"],
      channel: "#test",
      username: "development_test_bot",
    )
  end

  def self.create_stubbed_notifier
    Slack::Notifier.new "WEBHOOK_URL" do
      http_client NoOpHTTPClient
    end
  end

  def self.init_slack_client
    default_options = if Rails.env.production?
                        {
                          channel: ApplicationConfig["SLACK_CHANNEL"],
                          username: "activity_bot"
                        }
                      elsif Rails.env.test?
                        {
                          channel: "#test",
                          username: "development_test_bot"
                        }
                      end

    webhook_url = ApplicationConfig["SLACK_WEBHOOK_URL"] || ""
    use_no_op_client = Rails.env.test? || webhook_url.blank?

    Slack::Notifier.new(webhook_url) do
      defaults(default_options)
      http_client(NoOpHTTPClient) if use_no_op_client
    end
  end
end

SlackClient = SlackNotifierInitializer.init_slack_client
