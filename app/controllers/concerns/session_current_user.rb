module SessionCurrentUser
  extend ActiveSupport::Concern

  # Extracts the current user ID from the session
  def session_current_user_id
    return unless session["warden.user.user.key"]

    # the value is in the format [[1], "..."] where 1 is the ID
    session["warden.user.user.key"].first.first
  end
end
