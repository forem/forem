module CoAuthorInvitationsHelper
  # The editor's co-author invitation picker is shown to the post's author only, since invitees
  # are drawn from the author's followers.
  def co_author_invitations_enabled_for?(article)
    return false unless user_signed_in?
    return false if article.user_id.present? && article.user_id != current_user.id

    feature_flag_enabled?(:co_author_invitations)
  end

  def co_author_invitations_editor_data(article)
    return [] if article.new_record?

    article.co_author_invitations.includes(:user).order(:created_at).map do |invitation|
      { id: invitation.id, status: invitation.status, user: co_author_invitee_data(invitation.user) }
    end
  end

  def co_author_invitee_data(user)
    { id: user.id, name: user.name, username: user.username, profile_image_90: user.profile_image_90 }
  end
end
