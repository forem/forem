class NoOpHTTPClient
  def self.post(uri, params = {})
    # bonus, you could log or observe posted params here
  end
end

def create_normal_notifier
  Slack::Notifier.new(
    ApplicationConfig["SLACK_WEBHOOK_URL"],
    channel: ApplicationConfig["SLACK_CHANNEL"],
    username: "activity_bot",
  )
end

def create_test_channel_notifier
  return create_stubbed_notifier if ApplicationConfig["SLACK_WEBHOOK_URL"].blank?

  Slack::Notifier.new(
    ApplicationConfig["SLACK_WEBHOOK_URL"],
    channel: "#test",
    username: "development_test_bot",
  )
end

def create_stubbed_notifier
  Slack::Notifier.new "WEBHOOK_URL" do
    http_client NoOpHTTPClient
  end
end

# TODO: [@thepracticaldev/oss] remove this when Sidekiq has exhausted RateLimitCheckerWorker
::SlackBot = case Rails.env # rubocop:disable Naming/ConstantName
             when "production"
               create_normal_notifier
             when "development"
               create_test_channel_notifier
             when "test"
               create_stubbed_notifier
             end

def init_slack_client
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

  webhook_url = ApplicationConfig["SLACK_WEBHOOK_URL"]
  use_no_op_client = Rails.env.test? || webhook_url.blank?

  Slack::Notifier.new(webhook_url) do
    defaults(default_options)
    http_client(NoOpHTTPClient) if use_no_op_client
  end
end

SlackClient = init_slack_client
