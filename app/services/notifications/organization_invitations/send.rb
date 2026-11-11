# Asks the invitee to join an organization. The notification renders accept/decline actions.
module Notifications
  module OrganizationInvitations
    class Send
      def self.call(...)
        new(...).call
      end

      # @param membership [OrganizationMembership] a pending membership
      # @param inviter [User, nil]
      def initialize(membership, inviter: nil)
        @membership = membership
        @inviter = inviter
      end

      def call
        # find_or_create keeps a retried job from tripping the notifications uniqueness validation.
        Notification.find_or_create_by!(user_id: membership.user_id, notifiable: membership,
                                        action: INVITED) do |notification|
          notification.json_data = OrganizationInvitations.json_data(membership, inviter: inviter)
        end
      end

      private

      attr_reader :membership, :inviter
    end
  end
end
