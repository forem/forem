# Timber.io Ruby Configuration - Simple Structured Logging
#
#  ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^
# /|\/|\/|\ /|\    /\-_--\    /|\/|\ /|\/|\/|\ /|\/|\
# /|\/|\/|\ /|\   /  \_-__\   /|\/|\ /|\/|\/|\ /|\/|\
# /|\/|\/|\ /|\   |[]| [] |   /|\/|\ /|\/|\/|\ /|\/|\
# -------------------------------------------------------------------
# Website:       https://timber.io
# Documentation: https://timber.io/docs
# Support:       support@timber.io
# -------------------------------------------------------------------

config = Timber::Config.instance
config.integrations.action_view.silence = true
config.integrations.active_record.silence = !Rails.env.development?
config.integrations.rack.http_events.collapse_into_single_event = true

config.integrations.rack.http_events.silence_request = lambda do |_rack_env, rack_request|
  rack_request.path.match?(%r{^/page_views/\d{1,9}})
end

config.integrations.rack.user_context.custom_user_hash = lambda do |rack_env|
  session_user_id = rack_env["rack.session"].to_h["warden.user.user.key"]&.first&.first
  if session_user_id
    {
      id: session_user_id
    }
  end
end

# Add additional configuration here.
# For a full list of configuration options and their explanations see:
# http://www.rubydoc.info/github/timberio/timber-ruby/Timber/Config
