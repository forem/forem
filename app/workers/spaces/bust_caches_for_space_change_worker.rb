module Spaces
  # Conditionally delete the async cache when a Space changes
  #
  # @note Good news for those of you using Redis as your cache store, you have access to `Rails.cache.delete_matched`
  #
  # @see https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-i-delete_matched
  class BustCachesForSpaceChangeWorker < BustCacheBaseWorker
    def perform
      return unless Rails.cache.respond_to?(:delete_matched)

      # Addresses the cache in: app/views/stories/tagged_articles/_sidebar.html, which has
      # conditional rendering of buttons based on the state of the space.
      Rails.cache.delete_matched("tag-sidebar-*")
    end
  end
end
