module Notifications
  # Notifications for CoAuthorInvitation: the invitee is asked to confirm ("Invited"), and the
  # author hears back once the invitee accepts ("Accepted").
  module CoAuthorInvitations
    INVITED = "Invited".freeze
    ACCEPTED = "Accepted".freeze

    # @param invitation [CoAuthorInvitation]
    # @param user [User] the person the recipient is hearing from
    def self.json_data(invitation, user:)
      article = invitation.article
      {
        user: Notifications.user_data(user),
        # current_state_path, not path: invitations can be sent from drafts, and the invitee needs
        # the preview link to read the post before deciding.
        article: { id: article.id, title: article.title, path: article.current_state_path },
        co_author_invitation: { id: invitation.id, status: invitation.status }
      }
    end
  end
end
