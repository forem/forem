# DEV uses the RedisCloud Heroku Add-On which comes with the predefiend env variable REDISCLOUD_URL
redis_url = ENV["REDISCLOUD_URL"]
redis_url ||= ApplicationConfig["REDIS_URL"]

uri = URI.parse(redis_url)
RedisClient = Redis.new(host: uri.host, port: uri.port)
