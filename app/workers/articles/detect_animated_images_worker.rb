module Articles
  class DetectAnimatedImagesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 5, lock: :until_executing

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      detected = Articles::DetectAnimatedImages.call(article)
      return unless detected

      EdgeCache::BustArticle.call(article)
    end
  end
end
