module Metrics
  class RecordDailyUsageWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      articles_min_15_score_past_24h = Article.published.where("score >= 15").size
      DataDogStatsClient.count("articles.min_15_score_past_24h", articles_min_15_score_past_24h, tags: { resource: "articles" })

      first_articles_past_24h = Article.where(nth_published_by_author: 1).size
      DataDogStatsClient.count("articles.first_past_24h", first_articles_past_24h, tags: { resource: "articles" })

      new_users_min_1_comment_past_24h = User.where("comments_count >= ? AND created_at > ?", 1, 24.hours.ago).size
      DataDogStatsClient.count("users.new_min_1_comment_past_24h", new_users_min_1_comment_past_24h, tags: { resource: "users" })
    end
  end
end
