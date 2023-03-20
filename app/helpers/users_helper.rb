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
end
