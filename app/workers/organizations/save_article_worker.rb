module Organizations
  class SaveArticleWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(article_id)
      Article.find(article_id).save
    end
  end
end
