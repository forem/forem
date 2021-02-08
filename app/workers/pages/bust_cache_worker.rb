module Pages
  class BustCacheWorker < BustCacheBaseWorker
    def perform(slug)
      return if slug.blank?

      EdgeCache::BustPage.call(slug)
    end
  end
end
