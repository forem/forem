module Slack
  # a thin wrapper on Slack::Notifier
  # for additional options, see https://github.com/stevenosloan/slack-notifier
  class Announcer
    def initialize(message:, channel:, username:, icon_emoji:)
      @message = message
      @channel = channel
      @username = username
      @icon_emoji = icon_emoji
    end

    def self.call(...)
      new(...).call
    end

    def call
      return if [message, channel, username, icon_emoji].any?(&:blank?)

      SlackClient.ping(
        message,
        channel: channel,
        username: username,
        icon_emoji: icon_emoji,
      )
    end

    private

    attr_reader :message, :channel, :username, :icon_emoji
  end
end
