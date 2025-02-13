module Notifications
  module NewMention
    class Send
      include ActionView::Helpers::TextHelper

      delegate :user_data, to: Notifications
      delegate :comment_data, to: Notifications
      delegate :article_data, to: Notifications

      def self.call(...)
        new(...).call
      end

      def initialize(mention)
        @mention = mention
      end

      def call
        return if mention.mentionable.score.negative?

        Notification.create(
          user_id: mention.user_id,
          notifiable_id: mention.id,
          notifiable_type: "Mention",
          subforem_id: mention.mentionable.subforem_id,
          action: nil,
          json_data: json_data,
        )

        # Send PNs using Rpush - respecting users' notificaton delivery settings
        return unless Users::NotificationSetting.find_by(user_id: mention.user_id)&.mobile_mention_notifications?

        target = mention.user_id
        message_key, mentionable_title =
          if mention.mentionable.is_a?(Article)
            ["views.notifications.mention.article_mobile", mention.mentionable.title.strip]
          else
            ["views.notifications.mention.comment_mobile", mention.mentionable.commentable.title.strip]
          end

        PushNotifications::Send.call(
          user_ids: [target],
          title: I18n.t("services.notifications.new_mention.new"),
          body: "#{I18n.t(
            message_key,
            user: mention.mentionable.user.username,
            title: mentionable_title, # For an article this should be title, for comment should be article's title
          )}:\n" \
              "#{strip_tags(mention.mentionable.processed_html).strip}",
          payload: {
            url: URL.url(mention.mentionable.path),
            type: "new mention"
          },
        )
      end

      private

      attr_reader :mention

      def json_data
        data = { user: user_data(mention.mentionable.user) }

        case mention.mentionable_type
        when "Comment"
          data[:comment] = comment_data(mention.mentionable)
        when "Article"
          data[:article] = article_data(mention.mentionable)
        end

        data
      end
    end
  end
end
