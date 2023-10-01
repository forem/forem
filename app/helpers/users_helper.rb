module UsersHelper
  USER_COMMENTS_PARTIAL = "users/comments_section".freeze
  COMMENTS_LOCKED_PARTIAL = "users/comments_locked_cta".freeze

  def user_comments_section
    if user_signed_in?
      USER_COMMENTS_PARTIAL
    else
      COMMENTS_LOCKED_PARTIAL
    end
  end

  def user_social_image(user)
    if user.instance_of?(User) && user&.profile&.social_image.present?
      user.profile.social_image
    else
      Settings::General.main_social_image
    end
  end
end
