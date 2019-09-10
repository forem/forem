# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_store,
  key: ENV["SESSION_KEY"],
  servers: ENV["REDIS_URL"],
  expires_in: ENV["SESSION_EXPIRY_SECONDS"].to_i
