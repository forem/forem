module Articles
  class ScoreCalcJob < ApplicationJob
    queue_as :articles_score_calc

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_columns(score: article.reactions.sum(:points),
                             hotness_score: BlackBox.article_hotness_score(article),
                             spaminess_rating: BlackBox.calculate_spaminess(article))
      article.index!
    end
  end
end
