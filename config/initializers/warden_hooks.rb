Warden::Manager.after_authentication do |user, auth, _opts|
  # Only track sessions for Devise's User model
  next unless user.is_a?(User)

  # Access the request object
  env = auth.request.env
  request = ActionDispatch::Request.new(env)

  # Update Devise::Trackable fields
  user.update_tracked_fields!(request)

  # Save changes to the user record
  user.save(validate: false)

  if FeatureFlag.enabled?(:fastly_edge_feed_mirror) && EdgeFeed::TokenSigner.configured?
    EdgeFeed::TokenSigner.set_user_cookie(request.cookie_jar, user_id: user.id, secure: request.ssl?)
  end
end

Warden::Manager.before_logout do |_user, auth, _opts|
  next unless FeatureFlag.enabled?(:fastly_edge_feed_mirror)

  request = ActionDispatch::Request.new(auth.request.env)
  EdgeFeed::TokenSigner.clear_user_cookie(request.cookie_jar)
end
