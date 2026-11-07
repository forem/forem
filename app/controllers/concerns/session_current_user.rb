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

  # Returns the current user's ID from the session after validating Devise's
  # authenticatable_salt (without hydrating the full User model), falling back
  # to Warden's remember_user_token strategy when the session has no user key
  # but a remember_user_token cookie is present.
  def session_or_remembered_user_id(validate_salt: true)
    return @current_user.id if @token_authenticated && @current_user
    return @validated_session_user_id if defined?(@validated_session_user_id) && validate_salt

    if (key = session["warden.user.user.key"])
      return resolve_warden_session_key_id(key, validate_salt: validate_salt)
    end

    restore_remembered_user_id
  end

  # Validates a preloaded narrow User record against the session's Devise authenticatable_salt.
  def valid_session_viewer?(viewer)
    return false unless viewer
    return true if @token_authenticated || @remembered_user_restored
    return false unless (key = session["warden.user.user.key"])

    viewer.authenticatable_salt.to_s == key[1].to_s
  end

  def remembered_user_restored?
    @remembered_user_restored == true || request.session_options[:renew] == true
  end

  private

  def resolve_warden_session_key_id(key, validate_salt:)
    user_id = key.first&.first
    return unless user_id

    request.session_options[:skip] = false if request.session_options[:renew]
    return user_id unless validate_salt

    @validated_session_user_id = session_salt_valid?(user_id, key[1]) ? user_id : nil
  end

  def restore_remembered_user_id
    return if cookies[:remember_user_token].blank?

    user = request.env["warden"]&.authenticate(scope: :user)
    if user
      @remembered_user_restored = true
      request.session_options[:skip] = false
    end
    @validated_session_user_id = user&.id
  end

  def session_salt_valid?(user_id, session_salt)
    encrypted_password = User.where(id: user_id).pick(:encrypted_password)
    return false if encrypted_password.nil?

    encrypted_password[0, 29] == session_salt.to_s
  end
end
