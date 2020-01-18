module Metrics
  class RecordDailyUsageWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      articles_min_15_score_past_24h = Article.published.where("score >= ? AND published_at > ?", 15, 1.day.ago).size
      DataDogStatsClient.count("articles.min_15_score_past_24h", articles_min_15_score_past_24h, tags: { resource: "articles" })

      first_articles_past_24h = Article.where(nth_published_by_author: 1).where("published_at > ?", 1.day.ago).size
      DataDogStatsClient.count("articles.first_past_24h", first_articles_past_24h, tags: { resource: "articles" })

      new_users_min_1_comment_past_24h = User.where("comments_count >= ? AND created_at > ?", 1, 24.hours.ago).size
      DataDogStatsClient.count("users.new_min_1_comment_past_24h", new_users_min_1_comment_past_24h, tags: { resource: "users" })

      nagative_reactions_past_24h = Reaction.where("points < 0").where("created_at > ?", 1.day.ago).size
      DataDogStatsClient.count("reactions.negative_past_24h", nagative_reactions_past_24h, tags: { resource: "reactions" })

      reports_past_24_hours = FeedbackMessage.where(category: ["spam", "other", "rude or vulgar", "harassment"]).where("created_at > ?", 1.day.ago).size
      DataDogStatsClient.count("feedback_messages.reports_past_24_hours", reports_past_24_hours, tags: { resource: "feedback_messages" })

      get_days_active_past_week_counts
    end

    private

    def get_days_active_past_week_counts
      ids_by_day = []
      7.times do |i|
        ids_by_day << PageView.where("created_at > ? AND created_at < ?", (i + 1).days.ago, i.days.ago).where.not(user_id: nil).pluck(:user_id).uniq
      end
      non_new_user_ids = User.where("created_at < ?", 7.days.ago).where(id: ids_by_day.flatten).pluck(:id)
      new_user_ids = User.where("created_at > ?", 7.days.ago).where(id: ids_by_day.flatten).pluck(:id)
      record_active_days_of_group(ids_by_day, non_new_user_ids, "established")
      record_active_days_of_group(ids_by_day, new_user_ids, "new")
    end

    def record_active_days_of_group(ids_by_day, user_ids, group)
      user_ids_by_day = ids_by_day.map { |a| a & user_ids }
      distinct_user_values = user_ids_by_day.flatten.group_by(&:itself).transform_values(&:count).values
      distinct_counts = distinct_user_values.group_by(&:itself).transform_values(&:count)
      distinct_counts.keys.each do |key|
        DataDogStatsClient.gauge("users.#{group}_active_#{key}_days_past_7_days", distinct_counts[key], tags: { resource: "users" })
      end
    end
  end
end
