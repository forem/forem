# Be sure to restart your server when you modify this file.

# we want a default in case the expiration is not set or set to 0
# because 0 is an invalid value
app_config_expires_in = ApplicationConfig["SESSION_EXPIRY_SECONDS"].to_i
expires_in = app_config_expires_in.positive? ? app_config_expires_in : 2.weeks.to_i

Rails.application.config.session_store :redis_store,
                                       key: ApplicationConfig["SESSION_KEY"],
                                       servers: ApplicationConfig["REDIS_URL"],
                                       expires_in: expires_in
