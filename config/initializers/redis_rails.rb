# DEV uses the RedisCloud Heroku Add-On which comes with the predefined env variable REDISCLOUD_URL
redis_url = ENV["REDISCLOUD_URL"]
redis_url ||= ApplicationConfig["REDIS_URL"]

RedisRailsCache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
