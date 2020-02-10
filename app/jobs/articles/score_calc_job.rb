module Articles
  class ScoreCalcJob < ApplicationJob
    queue_as :articles_score_calc

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      article.update_score
      article.user&.calculate_score
      article.index!
    end
  end
end
