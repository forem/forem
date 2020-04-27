module ActiveSupport
  module Cache
    class RedisCacheStore
      def increment(name, amount = 1, options = nil)
        instrument :increment, name, amount: amount do
          failsafe :increment do
            options = merged_options(options)
            key = normalize_key(name, options)
            res = redis.with do |client|
              client.incrby(key, amount).tap do
                if options[:expires_in] && client.ttl(key).negative?
                  client.expire(key, options[:expires_in].to_i)
                end
              end
            end
            res
          end
        end
      end
    end
  end
end
