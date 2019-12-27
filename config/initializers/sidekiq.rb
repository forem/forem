require "sidekiq/web"
# Sidekiq sessions don't play well with Redis based sessions and Devise
# <https://github.com/mperham/sidekiq/wiki/Monitoring#sessions-being-lost>
Sidekiq::Web.set :sessions, false

Sidekiq.configure_server do |config|
  sidekiq_url = ApplicationConfig["REDIS_SIDEKIQ_URL"] || ApplicationConfig["REDIS_URL"]
  config.redis = { url: sidekiq_url }
end
