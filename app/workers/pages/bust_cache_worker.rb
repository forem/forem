module Pages
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(slug, cache_buster = "CacheBuster")
      return if slug.blank?

      cache_buster.constantize.bust_page(slug)
    end
  end
end
