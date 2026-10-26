# Used throughout the app to access a user id through the session
module SessionCurrentUser
  extend ActiveSupport::Concern

  # Extracts the current user ID from the session.
  #
  # @note Do NOT use `session_current_user_id` to personalize HTML or JSON responses
  #   inside edge-cached controller actions (`set_cache_control_headers` /
  #   `RequestStore.store[:edge_caching_in_place]`) or shared Rails fragment caches.
  #   Fastly varies edge-cached pages only on `X-Loggedin` (`logged-in` vs. `logged-out`),
  #   not per-viewer session, so using `session_current_user_id` on a cached path
  #   bypasses {EdgeCacheSafetyCheck#current_user} and leaks the first viewer's state
  #   to all other signed-in users.
  def session_current_user_id
    return @current_user.id if @token_authenticated && @current_user
    return unless (key = session["warden.user.user.key"])
    # the value is in the format [[1], "..."] where 1 is the ID
    key.first.first
  end
end
