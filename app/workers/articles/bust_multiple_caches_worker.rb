module Articles
  class BustMultipleCachesWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(article_ids)
      Article.select(:id, :path).where(id: article_ids).find_each do |article|
        EdgeCache::Bust.call(article.path)
        EdgeCache::Bust.call("#{article.path}?i=i")
      end
    end
  end
end
