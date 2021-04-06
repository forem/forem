module Slack
  module Messengers
    class Feedback
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        %<user_detail>s
        Category: %<category>s
        Internal Report: %<reports_url>s
        *_ Reported URL: %<reported_url>s _*
        -----
        *Message:* %<message>s
      TEXT

      USER_DETAIL_TEMPLATE = <<~TEXT.chomp.freeze
        *Logged in user:*
        reporter: %<username>s - %<url>s
        email: <mailto:%<email>s|%<email>s>
      TEXT

      def initialize(type:, category:, reported_url:, message:, user: nil)
        @user = user
        @type = type
        @category = category
        @reported_url = reported_url
        @message = message
      end

      def self.call(...)
        new(...).call
      end

      def call
        reports_url = URL.url(
          Rails.application.routes.url_helpers.admin_reports_path,
        )

        final_message = format(
          MESSAGE_TEMPLATE,
          user_detail: user_detail,
          category: category,
          reports_url: reports_url,
          reported_url: reported_url,
          message: message,
        )

        Slack::Messengers::Worker.perform_async(
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

        format(
          USER_DETAIL_TEMPLATE,
          username: user.username,
          url: URL.user(user),
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
