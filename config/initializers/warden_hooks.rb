Warden::Manager.after_authentication do |user, auth, opts|
  # Only track sessions for Devise's User model
  next unless user.is_a?(User)

  # Access the session ID for this request
  env = auth.request.env
  rails_session = env['rack.session']
  
  if rails_session && user.present?
    # Retrieve the session ID from Rails' session options
    session_id = rails_session.id
    
    # Store the session ID in Redis under the user's key
    # Key format: "user:#{user.id}:sessions"
    Redis.current.sadd("user:#{user.id}:sessions", session_id)
  end
end