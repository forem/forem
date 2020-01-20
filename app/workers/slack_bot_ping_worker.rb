class SlackBotPingWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :default, retry: 10

  def perform(message, channel, username, icon_emoji)
    SlackBot.ping(message, channel: channel, username: username, icon_emoji: icon_emoji)
  end
end
