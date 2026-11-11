module Notifications
  # Notifications for a pending OrganizationMembership: the invitee is asked to join the
  # organization ("Invited") and can accept or decline right from the notifications page.
  module OrganizationInvitations
    INVITED = "Invited".freeze

    # @param membership [OrganizationMembership]
    # @param inviter [User, nil] the person who sent the invitation, when known
    def self.json_data(membership, inviter: nil)
      data = {
        organization: Notifications.organization_data(membership.organization),
        organization_invitation: { id: membership.id, status: membership.pending? ? "pending" : "accepted" }
      }
      data[:user] = Notifications.user_data(inviter) if inviter
      data
    end
  end
end
