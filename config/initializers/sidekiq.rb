require "sidekiq/web"
# Sidekiq sessions don't play well with Redis based sessions and Devise
# <https://github.com/mperham/sidekiq/wiki/Monitoring#sessions-being-lost>
Sidekiq::Web.set :sessions, false

Sidekiq.configure_server do |config|
  sidekiq_url = ApplicationConfig["REDIS_SIDEKIQ_URL"] || ApplicationConfig["REDIS_URL"]
  # On Heroku this configuration is overridden and Sidekiq will point at the redis
  # instance given by the ENV variable REDIS_PROVIDER
  config.redis = { url: sidekiq_url }

  config.server_middleware do |chain|
    chain.add Sidekiq::HoneycombMiddleware
  end
end
