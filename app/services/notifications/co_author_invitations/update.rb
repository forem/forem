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
          invitation.notifications.where(user_id: author_id, action: ACCEPTED).delete_all
        end
      end

      private

      attr_reader :invitation

      def refresh_invitee_notification
        invitation.notifications.where(user_id: invitation.user_id, action: INVITED).find_each do |notification|
          json_data = notification.json_data.deep_merge("co_author_invitation" => { "status" => invitation.status })
          notification.update!(json_data: json_data, read: true)
        end
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
