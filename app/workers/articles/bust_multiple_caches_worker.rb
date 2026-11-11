module Articles
  class BustMultipleCachesWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })
    sidekiq_options queue: :low_priority, retry: 10

    def perform(article_ids)
      ids = Array.wrap(article_ids).compact
      return if ids.empty?

      EdgeCache::PurgeByKey.call(
        ids.map { |id| "articles/#{id}" },
        fallback_paths: -> { Article.where(id: ids).pluck(:path) },
      )
    end
  end
end
