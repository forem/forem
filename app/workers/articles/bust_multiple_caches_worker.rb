module Articles
  class BustMultipleCachesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(article_ids, cache_buster = "CacheBuster")

      Article.select(:id, :path).where(id: article_ids).find_each do |article|
        cache_buster.constantize.bust_article(article.path)
        cache_buster.constantize.bust_article("#{article.path}?i=i")
      end
    end
  end
end
