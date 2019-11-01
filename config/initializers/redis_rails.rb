# DEV uses the RedisCloud Heroku Add-On which comes with the predefined env variable REDISCLOUD_URL
redis_url = ENV["REDISCLOUD_URL"]
redis_url ||= ApplicationConfig["REDIS_URL"]
DEFAULT_EXPIRATION = 24.hours.to_i.freeze

if Rails.env.test?
  RedisRailsCache = ActiveSupport::Cache::NullStore.new
# Uncomment these lines to use MemoryStory in development
# elsif Rails.env.development?
#   RedisRailsCache = ActiveSupport::Cache::MemoryStore.new
else
  RedisRailsCache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url, expires_in: DEFAULT_EXPIRATION)
end
