module Pages
  class BustCacheWorker < BustCacheBaseWorker
    def perform(slug, cache_buster = "CacheBuster")
      return if slug.blank?

      cache_buster.constantize.bust_page(slug)
    end
  end
end
