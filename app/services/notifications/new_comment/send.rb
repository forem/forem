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
        user_ids = comment.ancestors.select(:user_id).where(receive_notifications: true).pluck(:user_id).to_set
        user_ids.add(comment.commentable.user_id) if comment.commentable.receive_notifications
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
          send_push_notifications(user_id, "@#{comment.user.username} replied to you:", comment.title, "/notifications/comments") if User.find_by(id: user_id)&.mobile_comment_notifications
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

      def send_push_notifications(user_id, title, body, path)
        return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64

        payload = {
          apns: {
            aps: {
              alert: {
                title: title,
                body: CGI.unescapeHTML(body.strip!)
              }
            },
            data: {
              url: "https://dev.to" + path
            }
          }
        }
        Pusher::PushNotifications.publish(interests: ["user-notifications-#{user_id}"], payload: payload)
      end
    end
  end
end
