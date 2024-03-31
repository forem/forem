module Slack
  module Messengers
    class Feedback
      def self.call(...)
        new(...).call
      end

      def initialize(type:, category:, reported_url:, message:, user: nil)
        @user = user
        @type = type
        @category = category
        @reported_url = reported_url
        @message = message
      end

      def call
        reports_url = URL.url(
          Rails.application.routes.url_helpers.admin_reports_path,
        )

        final_message = I18n.t(
          "services.slack.messengers.feedback.final_message",
          user_detail: user_detail,
          category: category,
          reports_url: reports_url,
          reported_url: reported_url,
          message: message,
        )

        Slack::Messengers::Worker.perform_async(
          "message" => final_message,
          "channel" => type,
          "username" => "#{type}_bot",
          "icon_emoji" => emoji,
        )
      end

      private

      attr_reader :user, :type, :category, :reported_url, :message

      def user_detail
        return I18n.t("services.slack.messengers.feedback.anonymous_report") unless user

        I18n.t(
          "services.slack.messengers.feedback.body",
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
