module Articles
  class DetectHumanLanguageJob < ApplicationJob
    queue_as :articles_detect_human_language

    def perform(article_id)
      article = Article.find_by(id: article_id)
      article&.update_column(:language, LanguageDetector.new(article).detect)
    end
  end
end
