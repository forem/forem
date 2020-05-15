module ActiveSupport
  module Cache
    class RedisCacheStore
      def increment(name, amount = 1, options = nil)
        # With Rails 5.2.4, RedisCacheStore#increment method does not support option :expires_in.
        # In order to workaround, we call expire command if the key is incremented at the first time.
        # This patch should be removed when upgrading to Rails 6.
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
