# Accepts a pending invitation, crediting the invitee as a co-author on the article.
module CoAuthorInvitations
  class Accept
    def self.call(...)
      new(...).call
    end

    # @param invitation [CoAuthorInvitation]
    def initialize(invitation)
      @invitation = invitation
    end

    # @return [Boolean] whether the invitation was accepted
    def call
      # Locking the article serializes responses to its invitations, so two co-authors accepting
      # at once can't overwrite each other's co_author_ids.
      accepted = article.with_lock do
        invitation.reload
        next false unless invitation.pending?
        # Invitations are for personal posts; pending ones lapse when a post moves under an
        # organization (see Article), so a response racing that move is turned away here.
        next false if article.organization_id.present?

        invitation.update!(status: :accepted, responded_at: Time.current)
        article.update!(co_author_ids: article.co_author_ids | [invitation.user_id])
        true
      end

      Notifications::CoAuthorInvitations::Update.call(invitation) if accepted
      accepted
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound # withdrawn in the meantime
      false
    end

    private

    attr_reader :invitation

    def article
      invitation.article
    end
  end
end
