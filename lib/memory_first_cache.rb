# MemoryFirstCache provides an L1/L2 cache pattern:
# - L1: In-process memory cache (fast, local)
# - L2: Redis cache (shared, distributed)
#
# This reduces latency and lessens load on Redis for frequently accessed data.
# The cache tries memory first, then Redis, then computes the value if needed.
class MemoryFirstCache
  DEFAULT_MEMORY_EXPIRES_IN = 10.minutes

  # Thread safety for memory store initialization
  @memory_store_mutex = Mutex.new

  class << self
    # Main method for fetching cached values with L1/L2 fallback
    # 
    # @param redis_key [String] The key to fetch from cache
    # @param memory_expires_in [Integer] TTL for memory cache (default: 10 minutes)
    # @param redis_expires_in [Integer] TTL for Redis cache (default: Rails cache behavior)
    # @param return_type [Symbol] Type conversion (:integer, :boolean, :string, :float, :symbol)
    # @return [Object] The cached value, converted to specified type if requested
    def fetch(redis_key, memory_expires_in: DEFAULT_MEMORY_EXPIRES_IN, redis_expires_in: nil, return_type: nil)
      memory_key = memory_key_for(redis_key)

      # 1) Try in-process memory first (L1 cache)
      mem = memory_store.read(memory_key)
      return convert_type(mem, return_type) unless mem.nil?

      # 2) Fall back to Redis-backed Rails.cache (L2 cache)
      val = Rails.cache.read(redis_key)
      unless val.nil?
        memory_store.write(memory_key, val, expires_in: memory_expires_in)
        return convert_type(val, return_type)
      end

      # 3) Compute-and-store if block provided
      return nil unless block_given?

      computed = yield
      # Write to Redis with the specified expiration (or default Rails cache behavior)
      if redis_expires_in
        Rails.cache.write(redis_key, computed, expires_in: redis_expires_in)
      else
        Rails.cache.write(redis_key, computed)
      end
      memory_store.write(memory_key, computed, expires_in: memory_expires_in)
      convert_type(computed, return_type)
    end

    # Delete a key from both memory and Redis caches
    def delete(redis_key)
      memory_store.delete(memory_key_for(redis_key))
      Rails.cache.delete(redis_key)
    end

    # Clear all keys from the memory store
    def clear
      memory_store.clear
    end

    # Reset the memory store instance (primarily for testing)
    # This forces a new memory store to be created on next access
    def reset_memory_store!
      @memory_store = nil
    end

    private

    def convert_type(value, return_type)
      return value if return_type.nil? || value.nil?
      
      # Handle type conversion for cases where Redis or other cache stores
      # may stringify values, or when we need explicit type coercion
      case return_type
      when :integer
        return nil if value == ""
        value.to_i
      when :string
        value.to_s
      when :boolean
        case value
        when true, "true", "1", 1 then true
        when false, "false", "0", 0, nil, "" then false
        else !!value
        end
      when :float
        return nil if value == ""
        value.to_f
      when :symbol
        value.to_sym
      else
        value
      end
    end

    def memory_key_for(redis_key)
      "memory_first:#{redis_key}"
    end

    def memory_store
      # First check is an optimization to avoid the mutex lock on every call
      return @memory_store if @memory_store

      @memory_store_mutex.synchronize do
        # Second check is the critical one to prevent the race condition
        @memory_store ||= ActiveSupport::Cache::MemoryStore.new(expires_in: DEFAULT_MEMORY_EXPIRES_IN)
      end
    end
  end
end


