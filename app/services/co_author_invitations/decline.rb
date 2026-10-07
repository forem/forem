# Declines an invitation. Declining one that was already accepted removes the invitee's
# co-author credit, so consent can be withdrawn after the fact.
module CoAuthorInvitations
  class Decline
    def self.call(...)
      new(...).call
    end

    # @param invitation [CoAuthorInvitation]
    def initialize(invitation)
      @invitation = invitation
    end

    # @return [Boolean] whether the invitation was declined
    def call
      # See Accept for why the article is locked.
      declined = article.with_lock do
        invitation.reload
        next false if invitation.declined?

        was_credited = invitation.accepted?
        invitation.update!(status: :declined, responded_at: Time.current)
        if was_credited && article.co_author_ids.include?(invitation.user_id)
          article.update!(co_author_ids: article.co_author_ids - [invitation.user_id])
        end
        true
      end

      Notifications::CoAuthorInvitations::Update.call(invitation) if declined
      declined
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
