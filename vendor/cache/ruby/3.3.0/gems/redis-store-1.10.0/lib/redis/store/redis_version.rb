class Redis
  class Store < self
    module RedisVersion
      def redis_version
        info('server')['redis_version']
      end

      def supports_redis_version?(version)
        (redis_version.split(".").map(&:to_i) <=> version.split(".").map(&:to_i)) >= 0
      end
    end
  end
end
