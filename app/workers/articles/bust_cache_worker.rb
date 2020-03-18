module Articles
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(article_id, cache_buster = "CacheBuster")
      article = Article.find_by(id: article_id)

      cache_buster.constantize.bust_article(article) if article
    end
  end
end
