class Redis
  class Store < self
    VERSION = '1.10.0'

    def self.redis_client_defined?
      # Doesn't work if declared as constant
      # due to unpredictable gem loading order
      # https://github.com/redis-rb/redis-client
      defined?(::RedisClient::VERSION)
    end
  end
end
