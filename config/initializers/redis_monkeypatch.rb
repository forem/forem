# config/initializers/redis_monkeypatch.rb

# Monkey patch the ActiveSupport::Cache::RedisCacheStore to write to both stores
# If the presence of REDIS_SECONDARY_CACHE_URL is defined and different from the primary store
# we will write to the secondary store as well as the first, for redundancy or cache store changeover.
class ActiveSupport::Cache::RedisCacheStore
  alias_method :original_write, :write

  if ENV["REDIS_SECONDARY_CACHE_URL"].present?
    SECONDARY_STORE = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_SECONDARY_CACHE_URL"])
  end

  def write(name, value, options = nil)
    # Write to the primary store as usual
    original_write(name, value, options)

    # Write to the secondary store if it's defined and different from the primary
    if defined?(SECONDARY_STORE) && ENV["REDIS_SECONDARY_CACHE_URL"] != ENV["REDIS_URL"]
      begin
        SECONDARY_STORE.write(name, value, options)
      rescue => e
        Rails.logger.error "Secondary Redis write failed: #{e.message}"
        # Optionally, implement retry logic or alerting here
      end
    end
  end
end