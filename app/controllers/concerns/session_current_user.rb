# Used throughout the app to access a user id through the session
module SessionCurrentUser
  extend ActiveSupport::Concern

  # Extracts the current user ID from the session
  def session_current_user_id
    return unless (key = session["warden.user.user.key"])

    # the value is in the format [[1], "..."] where 1 is the ID
    key.first.first
  end
end
