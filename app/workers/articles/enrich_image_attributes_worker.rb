module Articles
  class EnrichImageAttributesWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 5, lock: :until_executing

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      detected = Articles::EnrichImageAttributes.call(article)
      return unless detected

      EdgeCache::BustArticle.call(article)
    end
  end
end
