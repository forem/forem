# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_store,
  key: ApplicationConfig["SESSION_KEY"],
  servers: ApplicationConfig["REDIS_URL"],
  expires_in: ApplicationConfig["SESSION_EXPIRY_SECONDS"].to_i
