require "redis"

uri = URI.parse(ApplicationConfig["REDISCLOUD_URL"])
RedisClient = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
