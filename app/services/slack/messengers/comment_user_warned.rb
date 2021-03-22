module Slack
  module Messengers
    class CommentUserWarned
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        Activity: %<url>s
        Comment text: %<text>s
        ---
        Manage commenter - @%<username>s: %<internal_user_url>s
      TEXT

      def initialize(comment:)
        @comment = comment
        @user = comment.user
      end

      def self.call(...)
        new(...).call
      end

      def call
        return unless user.warned

        internal_user_url = URL.url(
          Rails.application.routes.url_helpers.admin_user_path(user),
        )

        message = format(
          MESSAGE_TEMPLATE,
          url: URL.comment(comment),
          text: comment.body_markdown.truncate(300),
          username: user.username,
          internal_user_url: internal_user_url,
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "warned-user-comments",
          username: "sloan_watch_bot",
          icon_emoji: ":sloan:",
        )
      end

      private

      attr_reader :comment, :user
    end
  end
end
