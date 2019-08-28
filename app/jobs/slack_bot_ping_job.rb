class SlackBotPingJob < ApplicationJob
  queue_as :slack_bot_ping

  def perform(message:, channel:, username:, icon_emoji:)
    SlackBot.ping message,
                  channel: channel,
                  username: username,
                  icon_emoji: icon_emoji
  end
end
