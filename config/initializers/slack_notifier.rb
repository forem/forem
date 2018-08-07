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

::SlackBot = case Rails.env # rubocop:disable Naming/ConstantName
             when "production"
               create_normal_notifier
             when "development"
               create_test_channel_notifier
             when "test"
               create_stubbed_notifier
             end
