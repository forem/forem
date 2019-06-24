module Tags
  class BustCacheJob < ApplicationJob
    queue_as :tags_bust_cache

    def perform(name, cache_buster = CacheBuster.new)
      cache_buster.bust_tag(name)
    end
  end
end
