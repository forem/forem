module Articles
  class ScoreCalcWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_score
      article.index!
      article.index_to_elasticsearch_inline
    end
  end
end
