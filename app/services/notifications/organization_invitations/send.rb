# Asks the invitee to join an organization. The notification renders accept/decline actions.
module Notifications
  module OrganizationInvitations
    class Send
      # @see #call
      def self.call(...)
        new(...).call
      end

      # @param membership [OrganizationMembership] a pending membership
      # @param inviter [User, nil]
      def initialize(membership, inviter: nil)
        @membership = membership
        @inviter = inviter
      end

      # Creates the invitee's notification, unless the invitation was answered or withdrawn first.
      #
      # The membership row is locked while we check it and create the notification, so an accept
      # or an administrator's removal running at the same time waits for us and then updates or
      # deletes the notification, instead of leaving behind a stale one with working buttons.
      #
      # @return [Notification, nil]
      def call
        membership.with_lock do
          next unless membership.pending?

          # find_or_create keeps a retried job from tripping the notifications uniqueness validation.
          Notification.find_or_create_by!(user_id: membership.user_id, notifiable: membership,
                                          action: INVITED) do |notification|
            # Lets Organizations::Delete find and remove these notifications with the organization's.
            notification.organization_id = membership.organization_id
            notification.json_data = OrganizationInvitations.json_data(membership, inviter: inviter)
          end
        end
      rescue ActiveRecord::RecordNotFound
        # The membership was removed while we were waiting for the lock.
        nil
      end

      private

      attr_reader :membership, :inviter
    end
  end
end
