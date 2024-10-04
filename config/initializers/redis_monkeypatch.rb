# config/initializers/redis_monkeypatch.rb

# Monkey patch the ActiveSupport::Cache::RedisCacheStore to write to both stores
# If the presence of REDIS_SECONDARY_CACHE_URL is defined and different from the primary store
# we will write to the secondary store as well as the first, for redundancy or cache store changeover.
class ActiveSupport::Cache::RedisCacheStore
  alias_method :original_write, :write

  def write(name, value, options = nil)
    # Write to the primary store as usual
    original_write(name, value, options)

    # Write to the secondary store if it's defined and different from the primary
    secondary_redis_url = ENV["REDIS_SECONDARY_CACHE_URL"]
    if secondary_redis_url.present? && secondary_redis_url != ENV["REDIS_URL"]
      secondary_store = ActiveSupport::Cache::RedisCacheStore.new(url: secondary_redis_url)
      secondary_store.write(name, value, options)
    end
  end
end