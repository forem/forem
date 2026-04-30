module Articles
  class GenerateSummaryWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 3 })

    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(article_id)
      return unless Ai::Base::DEFAULT_KEY.present?

      article = Article.find_by(id: article_id)
      return unless article

      return if article.score < 50 || article.comment_score < 25

      Ai::ArticleSummaryGenerator.new(article).call
    end
  end
end
