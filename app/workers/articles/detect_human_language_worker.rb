module Articles
  class DetectHumanLanguageWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_column(:language, LanguageDetector.new(article).detect)
    end
  end
end
