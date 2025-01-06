class SessionsController < Devise::SessionsController
  def destroy
    if user_signed_in?
      # Fetch all session IDs for the current user
      user_session_ids = Redis.current.smembers("user:#{current_user.id}:sessions")

      current_user.update_columns(current_sign_in_at: nil, current_sign_in_ip: nil)
      # Delete each session from Redis using the configured session key prefix
      session_key_prefix = ApplicationConfig["SESSION_KEY"]
      user_session_ids.each do |session_id|
        # Construct the full Redis key for each session
        redis_key = "#{session_key_prefix}:#{session_id}"
        Redis.current.del(redis_key)
      end

      # Remove the user's session tracking set
      Redis.current.del("user:#{current_user.id}:sessions")
    end

    # Call Devise's default sign-out behavior
    super
  end
end
