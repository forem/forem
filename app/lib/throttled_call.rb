class ThrottledCall
  KEY_TEMPLATE = "throttled_call.%<key>s".freeze

  # Executes the provided block and then blocks its execution for the provided
  # time interval
  #
  # @param key [String, Symbol] used for generating the Redis cache key
  # @param throttle_for [ActiveSupport::Duration] blocking time interval
  def self.perform(key, throttle_for:)
    namespaced_key = format(KEY_TEMPLATE, key: key)
    Rails.cache.fetch(namespaced_key, expires_in: throttle_for) do
      yield if block_given?
      true
    end
  end
end
