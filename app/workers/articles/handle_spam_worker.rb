module Articles
  class HandleSpamWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(article_id)
      article = Article.find_by(id: article_id)
      Spam::Handler.handle_article!(article: article) if article
      article.reload.update_score if article
    end
  end
end
