module Articles
  class ScoreCalcWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_score
    end
  end
end
