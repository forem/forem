class VideoPolicy < ApplicationPolicy
  # @return [Boolean] if the user can :create a video.
  # @raise [ApplicationPolicy::UserSuspendedError] if the user's suspended.
  # @raise [ApplicationPolicy::UserRequiredError] if the caller did not provide a user.
  #
  # @todo Consider extracting a user_is_established_in_community as this `user.created_at.before?`
  #       question rattles around in the code-base.  But I think we'd want guidance on configuring
  #       what that means.  [@jeremyf] envisions that we could use an admin setting to allow the
  #       administrators to set the number of days to consider a "new user".
  def create?
    return false unless Settings::General.enable_video_upload

    require_user_in_good_standing!
    return false unless user.created_at
    # Newly granted admins get to "short-circuit" the business logic of "were you created too
    # recently?"
    return user_any_admin? if ArticlePolicy.limit_post_creation_to_admins?

    user.created_at.before?(2.weeks.ago)
  end

  alias new? create?
end
