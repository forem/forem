module Slack
  module Messengers
    class Feedback
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        %<user_detail>s
        Category: %<category>s
        Internal Report: #{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/internal/reports
        *_ Reported URL: %<reported_url>s _*
        -----
        *Message:* %<message>s
      TEXT

      USER_DETAIL_TEMPLATE = <<~TEXT.chomp.freeze
        *Logged in user:*
        reporter: %<username>s - %<url>s
        email: <mailto:%<email>s|%<email>s>
      TEXT

      def initialize(user: nil, type:, category:, reported_url:, message:)
        @user = user
        @type = type
        @category = category
        @reported_url = reported_url
        @message = message
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        final_message = format(
          MESSAGE_TEMPLATE,
          user_detail: user_detail,
          category: category,
          reported_url: reported_url,
          message: message,
        )

        SlackBotPingWorker.perform_async(
          message: final_message,
          channel: type,
          username: "#{type}_bot",
          icon_emoji: emoji,
        )
      end

      private

      attr_reader :user, :type, :category, :reported_url, :message

      def user_detail
        return "*Anonymous report:" unless user

        username = user.username
        url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/#{username}"
        format(
          USER_DETAIL_TEMPLATE,
          username: username,
          url: url,
          email: user.email,
        )
      end

      def emoji
        if type == "abuse-reports"
          ":cry:"
        else
          ":robot_face:"
        end
      end
    end
  end
end
