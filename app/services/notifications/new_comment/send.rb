# send notifications about the new comment
module Notifications
  module NewComment
    class Send
      def initialize(comment)
        @comment = comment
      end

      delegate :user_data, :comment_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      def call
        user_ids = Set.new(comment_user_ids + subscribed_user_ids + top_level_user_ids + author_subscriber_user_ids)

        json_data = {
          user: user_data(comment.user),
          comment: comment_data(comment)
        }

        targets = []
        user_ids.delete(comment.user_id).each do |user_id|
          Notification.create(
            user_id: user_id,
            notifiable_id: comment.id,
            notifiable_type: comment.class.name,
            action: nil,
            json_data: json_data,
          )

          targets << "user-notifications-#{user_id}" if User.find_by(id: user_id)&.mobile_comment_notifications
        end

        # Sends the push notification to Pusher Beams channels. Batch is in place to respect Pusher 100 channel limit.
        targets.each_slice(100) { |batch| PushNotifications::Send.call(batch, comment) }

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
