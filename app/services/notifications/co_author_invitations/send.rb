# Asks the invitee to confirm a co-author credit. The notification renders accept/decline actions.
module Notifications
  module CoAuthorInvitations
    class Send
      def self.call(...)
        new(...).call
      end

      # @param invitation [CoAuthorInvitation]
      def initialize(invitation)
        @invitation = invitation
      end

      def call
        # find_or_create keeps a retried job from tripping the notifications uniqueness validation.
        Notification.find_or_create_by!(user_id: invitation.user_id, notifiable: invitation,
                                        action: INVITED) do |notification|
          notification.subforem_id = invitation.article.subforem_id
          notification.json_data = CoAuthorInvitations.json_data(invitation, user: invitation.article.user)
        end
      end

      private

      attr_reader :invitation
    end
  end
end
