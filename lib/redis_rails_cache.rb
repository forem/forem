# Temporary and will be removed after all cache keys have been moved over to Redis
class RedisRailsCache
  DEFAULT_EXPIRATION = 24.hours.to_i.freeze

  class << self
    def fetch(key_name, opts = {})
      # Default expire all keys after 24 hours if expiration is not given
      expires_in = opts[:expires_in] || DEFAULT_EXPIRATION

      if block_given?
        entry = client.get(key_name)
        return entry if entry.present?

        save_block_result_to_cache(key_name, expires_in) { |name| yield name }
      else
        client.get(key_name)
      end
    end

    def read(key_name)
      client.get(key_name)
    end

    def write(key_name, value, opts = {})
      client.set(key_name, value, ex: opts[:expires_in] || DEFAULT_EXPIRATION)
    end

    private

    def save_block_result_to_cache(key_name, expires_in)
      result = yield
      client.set(key_name, result, ex: expires_in)
      result
    end

    def client
      RedisClient
    end
  end
end
