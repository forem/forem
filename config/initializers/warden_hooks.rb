Warden::Manager.after_authentication do |user, auth, opts|
  # Only track sessions for Devise's User model
  next unless user.is_a?(User)

  # Access the request object
  env = auth.request.env
  request = ActionDispatch::Request.new(env)

  # Update Devise::Trackable fields
  user.update_tracked_fields!(request)

  # Save changes to the user record
  user.save(validate: false)

  # Additional session tracking logic (optional)
  rails_session = env['rack.session']
  if rails_session && user.present?
    session_id = rails_session.id
    Redis.current.sadd("user:#{user.id}:sessions", session_id)
  end
end