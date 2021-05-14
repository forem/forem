module Articles
  class DetectAnimatedImagesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 5, lock: :until_executing

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      Articles::DetectAnimatedImages.call(article)
    end
  end
end
