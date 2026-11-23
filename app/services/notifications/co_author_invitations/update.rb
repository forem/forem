# Brings an invitation's notifications in line with its status after the invitee responds: the
# invitee's card shows the outcome, and the author has an "accepted" notification only while the
# invitee is credited.
module Notifications
  module CoAuthorInvitations
    class Update
      def self.call(...)
        new(...).call
      end

      # @param invitation [CoAuthorInvitation]
      def initialize(invitation)
        @invitation = invitation
      end

      def call
        refresh_invitee_notification

        if invitation.accepted?
          notify_author
        else
          remove_author_notification
        end
      end

      private

      attr_reader :invitation

      def refresh_invitee_notification
        json_data = CoAuthorInvitations.json_data(invitation, user: invitation.article.user)
        invitation.notifications.where(user_id: invitation.user_id, action: INVITED).find_each do |notification|
          notification.update!(json_data: json_data, read: true)
          Notifications::SyncEvents.read_one(notification)
        end
      end

      def remove_author_notification
        notification_id = invitation.notifications.where(user_id: author_id, action: ACCEPTED).pick(:id)
        return unless notification_id && Notification.where(id: notification_id).delete_all.positive?

        Notifications::SyncEvents.removed(
          notifiable_type: "CoAuthorInvitation",
          notifiable_ids: [invitation.id],
          action: ACCEPTED,
          recipients: { author_id => notification_id },
          reason: "invitation_updated",
        )
      end

      def notify_author
        Notification.find_or_create_by!(user_id: author_id, notifiable: invitation, action: ACCEPTED) do |notification|
          notification.subforem_id = invitation.article.subforem_id
          notification.json_data = CoAuthorInvitations.json_data(invitation, user: invitation.user)
        end
      end

      def author_id
        invitation.article.user_id
      end
    end
  end
end
