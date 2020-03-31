class SlackBotPingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 10

  def perform(slack_data = {})
    # Sidekiq turns arguments into Strings so the Ruby keyword argument sorcery doesn't work here
    # prevent any mismatch between String keys and Symbol keys
    slack_data.symbolize_keys!

    message = slack_data[:message]
    channel = slack_data[:channel]
    username = slack_data[:username]
    icon_emoji = slack_data[:icon_emoji]

    # Double check for any nil values
    return unless message && channel && username && icon_emoji

    Slack::Announcer.call(
      message: message,
      channel: channel,
      username: username,
      icon_emoji: icon_emoji,
    )
  end
end
