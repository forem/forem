module Notifications
  class CoAuthorInvitationWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(invitation_id)
      invitation = CoAuthorInvitation.find_by(id: invitation_id)
      # The author may have withdrawn the invitation before this ran.
      return unless invitation&.pending?

      Notifications::CoAuthorInvitations::Send.call(invitation)
    end
  end
end
