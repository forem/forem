# Brings the invitee's notification in line with the membership once the invitation was accepted:
# the card shows the outcome instead of the accept/decline buttons. Declined invitations delete
# the membership, which deletes its notifications.
module Notifications
  module OrganizationInvitations
    class Update
      # @see #call
      def self.call(...)
        new(...).call
      end

      # @param membership [OrganizationMembership]
      def initialize(membership)
        @membership = membership
      end

      # Refreshes the invitee's notification card and marks it read.
      def call
        membership.notifications.where(user_id: membership.user_id, action: INVITED).find_each do |notification|
          inviter_data = notification.json_data["user"]
          json_data = OrganizationInvitations.json_data(membership)
          json_data[:user] = inviter_data if inviter_data
          notification.update!(json_data: json_data, read: true)
        end
      end

      private

      attr_reader :membership
    end
  end
end
