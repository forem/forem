module Podcasts
  class BustCacheJob < ApplicationJob
    queue_as :podcasts_bust_cache

    def perform(path, cache_buster = CacheBuster.new)
      cache_buster.bust_podcast(path)
    end
  end
end
