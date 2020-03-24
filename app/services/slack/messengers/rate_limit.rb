module Slack
  module Messengers
    class RateLimit
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        Rate limit exceeded (%<action>s). %<url>s
      TEXT

      def initialize(user:, action:)
        @user = user
        @action = action
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/#{user.username}"

        message = format(
          MESSAGE_TEMPLATE,
          action: action,
          url: url,
        )

        SlackBotPingWorker.perform_async(
          message: message,
          channel: "abuse-reports",
          username: "rate_limit",
          icon_emoji: ":hand:",
        )
      end

      private

      attr_reader :user, :action
    end
  end
end
