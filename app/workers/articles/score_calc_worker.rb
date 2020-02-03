module Articles
  class ScoreCalcWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_columns(score: article.reactions.sum(:points),
                             comment_score: article.comments.sum(:score),
                             hotness_score: BlackBox.article_hotness_score(article),
                             spaminess_rating: BlackBox.calculate_spaminess(article))
      article.index!
    end
  end
end
