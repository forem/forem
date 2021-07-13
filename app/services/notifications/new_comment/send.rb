# send notifications about the new comment

module Notifications
  module NewComment
    class Send
      def initialize(comment)
        @comment = comment
      end

      delegate :user_data, :comment_data, to: Notifications

      def self.call(...)
        new(...).call
      end

      def call
        return if comment.score.negative?

        user_ids = Set.new(comment_user_ids + subscribed_user_ids + top_level_user_ids + author_subscriber_user_ids)
        user_ids.delete(comment.user_id)

        json_data = {
          user: user_data(comment.user),
          comment: comment_data(comment)
        }

        user_ids.each do |user_id|
          Notification.create(
            user_id: user_id,
            notifiable_id: comment.id,
            notifiable_type: comment.class.name,
            action: nil,
            json_data: json_data,
          )
        end

        # Send PNs using Rpush - respecting users' notificaton delivery settings
        targets = User.joins(:notification_setting)
          .where(id: user_ids, notification_setting: { mobile_comment_notifications: true }).ids

        PushNotifications::Send.call(
          user_ids: targets,
          title: "@#{comment.user.username}",
          body: "Re: #{comment.parent_or_root_article.title.strip}",
          payload: {
            url: URL.url(comment.path),
            type: "new comment"
          },
        )

        return unless comment.commentable.organization_id

        Notification.create(
          organization_id: comment.commentable.organization_id,
          notifiable_id: comment.id,
          notifiable_type: comment.class.name,
          action: nil,
          json_data: json_data,
        )
        # no push notifications for organizations yet
      end

      private

      attr_reader :comment

      def user_ids_for(config_name)
        NotificationSubscription
          .where(notifiable_id: comment.commentable_id, notifiable_type: "Article", config: config_name)
          .pluck(:user_id)
      end

      def comment_user_ids
        comment.ancestors.where(receive_notifications: true).pluck(:user_id)
      end

      def subscribed_user_ids
        user_ids_for("all_comments")
      end

      def top_level_user_ids
        return [] if comment.ancestry.present?

        user_ids_for("top_level_comments")
      end

      def author_subscriber_user_ids
        return [] if comment.user_id != comment.commentable.user_id

        user_ids_for("only_author_comments")
      end
    end
  end
end
