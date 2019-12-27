Sidekiq.configure_server do |config|
  sidekiq_url = ApplicationConfig["REDIS_SIDEKIQ_URL"] || ApplicationConfig["REDIS_URL"]
  config.redis = { url: sidekiq_url }
end
