module Articles
  class BustMultipleCachesWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })
    sidekiq_options queue: :low_priority, retry: 10

    def perform(article_ids)
      Article.select(:id, :path).where(id: article_ids).find_each do |article|
        cache_bust = EdgeCache::Bust.new
        cache_bust.call(article.path)
        cache_bust.call("#{article.path}?i=i")
      end
    end
  end
end
