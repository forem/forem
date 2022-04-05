module Users
  # Conditionally delete the async cache when a Space changes
  #
  # @note Good news for those of you using Redis as your cache store, you have access to `Rails.cache.delete_matched`
  #
  # @see https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-i-delete_matched
  class BustCacheForSpaceChangeWorker < BustCacheBaseWorker
    def perform
      return unless Rails.cache.respond_to?(:delete_matched)

      Rails.cache.delete_matched("#{AsyncInfoController::ASYNC_INFO_CACHE_KEY_PREFIX}-*")
    end
  end
end
