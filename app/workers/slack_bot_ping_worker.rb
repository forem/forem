class SlackBotPingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 10

  def perform(slack_data = {})
    # prevent any mismatch between String keys and Symbol keys
    slack_data.symbolize_keys!

    SlackBot.ping(
      slack_data[:message],
      channel: slack_data[:channel],
      username: slack_data[:username],
      icon_emoji: slack_data[:icon_emoji],
    )
  end
end
