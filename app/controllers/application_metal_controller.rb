class ApplicationMetalController < ActionController::Metal
  # Any shared behavior across metal-oriented controllers can go here.

  def session_current_user_id
    # This method should stay in sync with the ApplicationController equivalent
    # Could/should be extracted to the appropriate place for ideal code sharing and efficiency

    session["warden.user.user.key"].flatten[0] if session["warden.user.user.key"].present?
  end
end
