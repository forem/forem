module Notifications
  class OrganizationInvitationWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(membership_id, inviter_id = nil)
      membership = OrganizationMembership.find_by(id: membership_id)
      # The invitation may have been answered or withdrawn before this ran.
      return unless membership&.pending?

      Notifications::OrganizationInvitations::Send.call(membership, inviter: User.find_by(id: inviter_id))
    end
  end
end
