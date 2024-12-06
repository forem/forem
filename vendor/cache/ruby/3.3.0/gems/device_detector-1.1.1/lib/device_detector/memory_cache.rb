# frozen_string_literal: true

class DeviceDetector
  class MemoryCache
    DEFAULT_MAX_KEYS = 5000
    STORES_NIL_VALUE = :__is_nil__

    attr_reader :data, :max_keys, :lock
    private :lock

    def initialize(config)
      @data = {}
      @max_keys = config[:max_cache_keys] || DEFAULT_MAX_KEYS
      @lock = Mutex.new
    end

    def set(key, value)
      lock.synchronize do
        purge_cache
        # convert nil values into symbol so we know a value is present
        cache_value = value.nil? ? STORES_NIL_VALUE : value
        data[String(key)] = cache_value
        value
      end
    end

    def get(key)
      value, _hit = get_hit(key)
      value
    end

    def get_or_set(key, value = nil)
      string_key = String(key)

      result, hit = get_hit(string_key)
      return result if hit

      value = yield if block_given?
      set(string_key, value)
    end

    private

    def get_hit(key)
      value = data[String(key)]
      is_hit = !value.nil? || value == STORES_NIL_VALUE
      value = nil if value == STORES_NIL_VALUE
      [value, is_hit]
    end

    def purge_cache
      key_size = data.size

      return if key_size < max_keys

      # always remove about 1/3 of keys to reduce garbage collecting
      amount_of_keys = key_size / 3

      data.keys.first(amount_of_keys).each { |key| data.delete(key) }
    end
  end
end
