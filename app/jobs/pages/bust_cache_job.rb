module Pages
  class BustCacheJob < ApplicationJob
    queue_as :pages_bust_cache

    def perform(slug, cache_buster = CacheBuster.new)
      cache_buster.bust_page(slug)
    end
  end
end
