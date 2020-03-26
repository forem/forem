# frozen_string_literal: true

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

        user_ids.delete(comment.user_id).each do |user_id|
          Notification.create(
            user_id: user_id,
            notifiable_id: comment.id,
            notifiable_type: comment.class.name,
            action: nil,
            json_data: json_data,
          )

          # Be careful with this basic first implementation of push notification. Has dependency of Pusher/iPhone sort of tough to test reliably.
          if User.find_by(id: user_id)&.mobile_comment_notifications
            send_push_notifications(user_id, "@#{comment.user.username}", "re: #{comment.parent_or_root_article.title.strip}", comment.title, "/notifications/comments")
          end
        end

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
        NotificationSubscription.
          where(notifiable_id: comment.commentable_id, notifiable_type: "Article", config: config_name).
          pluck(:user_id)
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

      def send_push_notifications(user_id, title, subtitle, body, path)
        return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64

        notification_url = App.url(path)
        payload = {
          apns: {
            aps: {
              alert: {
                title: title,
                subtitle: subtitle,
                body: CGI.unescapeHTML(body.strip)
              }
            },
            data: {
              url: notification_url
            }
          },
          fcm: {
            notification: {
              title: title,
              body: subtitle
            },
            data: {
              url: notification_url
            }
          }
        }
        Pusher::PushNotifications.publish(interests: ["user-notifications-#{user_id}"], payload: payload)
      end
    end
  end
end
