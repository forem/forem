module Events
  class BustCacheJob < ApplicationJob
    queue_as :events_bust_cache

    def perform(cache_buster = CacheBuster.new)
      cache_buster.bust_events
    end
  end
end
