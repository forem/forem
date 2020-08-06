# send notifications about the new comment

module Notifications
  module NewEndorsement
    class Send
      def initialize(endorsement)
        @endorsement = endorsement
      end

      delegate :user_data, :endorsement_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      def call
        #user_ids = Set.new(comment_user_ids + subscribed_user_ids + top_level_user_ids + author_subscriber_user_ids)

        json_data = {
          user: user_data(endorsement.user),
          endorsement: endorsement_data(endorsement)
        }

        targets = []
        #user_ids.delete(comment.user_id).each do |user_id|
        user_id = 3
        Notification.create(
          user_id: user_id,
          notifiable_id: endorsement.id,
          notifiable_type: endorsement.class.name,
          action: nil,
          json_data: json_data,
        )

        targets << "user-notifications-#{user_id}" if User.find_by(id: user_id)
        #end

        # Sends the push notification to Pusher Beams channels. Batch is in place to respect Pusher 100 channel limit.
        targets.each_slice(100) { |batch| send_push_notifications(batch) }

        # return unless comment.commentable.organization_id

        # Notification.create(
        #   organization_id: comment.commentable.organization_id,
        #   notifiable_id: comment.id,
        #   notifiable_type: comment.class.name,
        #   action: nil,
        #   json_data: json_data,
        # )
        # no push notifications for organizations yet
      end

      private

      attr_reader :endorsement

      # def user_ids_for(config_name)
      #   NotificationSubscription
      #     .where(notifiable_id: comment.commentable_id, notifiable_type: "Article", config: config_name)
      #     .pluck(:user_id)
      # end

      # def comment_user_ids
      #   comment.ancestors.where(receive_notifications: true).pluck(:user_id)
      # end

      # def subscribed_user_ids
      #   user_ids_for("all_comments")
      # end

      # def top_level_user_ids
      #   return [] if comment.ancestry.present?

      #   user_ids_for("top_level_comments")
      # end

      # def author_subscriber_user_ids
      #   return [] if comment.user_id != comment.commentable.user_id

      #   user_ids_for("only_author_comments")
      # end

      def send_push_notifications(channels)
        return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64

        Pusher::PushNotifications.publish_to_interests(
          interests: channels,
          payload: push_notification_payload,
        )
      end

      def push_notification_payload
        title = "@#{endorsement.user.username}"
        subtitle = "re: #{endorsement.last.title.strip}"
        data_payload = { url: URL.url("/notifications/comments") }
        {
          apns: {
            aps: {
              alert: {
                title: title,
                subtitle: subtitle,
                body: CGI.unescapeHTML(endorsement.content.strip)
              }
            },
            data: data_payload
          },
          fcm: {
            notification: {
              title: title,
              body: subtitle
            },
            data: data_payload
          }
        }
      end
    end
  end
end
